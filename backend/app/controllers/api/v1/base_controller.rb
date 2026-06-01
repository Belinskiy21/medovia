module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_request!

      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ArgumentError, with: :render_unprocessable_entity

      private

      def current_actor
        current_principal.actor
      end

      def current_role(healthcare_unit = nil)
        return current_principal.role if current_principal.kind == "service"
        return current_principal.record.role_for(healthcare_unit) if healthcare_unit

        current_principal.record.memberships.first&.role
      end

      def require_role!(*roles, healthcare_unit: nil)
        role = current_role(healthcare_unit)
        allowed = if current_principal.kind == "service"
          roles.include?(role)
        elsif healthcare_unit
          current_principal.record.role_in_unit?(healthcare_unit, *roles)
        else
          current_principal.record.role_in_any_unit?(*roles)
        end
        return if allowed

        render json: { error: "Role #{role || "none"} is not allowed to perform this action" }, status: :forbidden
      end

      def role_allowed?(*roles, healthcare_unit: nil)
        require_role!(*roles, healthcare_unit:)
        !performed?
      end

      def audit!(action, record, metadata = {})
        unit = healthcare_unit_for(record)
        AuditLog.create!(
          actor: current_actor,
          role: current_role(unit) || "service",
          action:,
          auditable_type: record.class.name,
          auditable_id: record.id,
          metadata:
        )
      end

      def unit_access_allowed?(healthcare_unit)
        return true if current_principal.kind == "service"
        return true if current_principal.record.memberships.exists?(healthcare_unit:)

        render json: { error: "No access to this healthcare unit" }, status: :forbidden
        false
      end

      def any_role_allowed?(*roles)
        return true if roles.include?(current_principal.role) && current_principal.kind == "service"
        return true if current_principal.kind == "user" && current_principal.record.role_in_any_unit?(*roles)

        render json: { error: "Role none is not allowed to perform this action" }, status: :forbidden
        false
      end

      def authenticate_request!
        token = bearer_token
        principal = token.present? ? AuthToken.authenticate(token) || service_principal(token) : nil

        if principal
          @current_principal = principal
        else
          render json: { error: "Authentication required" }, status: :unauthorized
        end
      end

      def current_principal
        @current_principal
      end

      def bearer_token
        authorization = request.headers["Authorization"].to_s
        scheme, token = authorization.split(" ", 2)
        token if scheme&.casecmp("Bearer")&.zero?
      end

      def service_principal(token)
        account = ServiceAccount.authenticate_bearer(token)
        return unless account

        AuthenticatedPrincipal.new(actor: account.identifier, role: account.role, kind: "service", record: account)
      end

      def healthcare_unit_for(record)
        case record
        when HealthcareUnit
          record
        when Medication, Order
          record.healthcare_unit
        when OrderLine
          record.order.healthcare_unit
        end
      end

      def render_unprocessable_entity(error)
        message = error.respond_to?(:record) ? error.record.errors.full_messages : [ error.message ]
        render json: { errors: message }, status: :unprocessable_entity
      end

      def render_not_found
        render json: { error: "Record not found" }, status: :not_found
      end
    end
  end
end
