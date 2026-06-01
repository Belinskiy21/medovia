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

      def current_role
        current_principal.role
      end

      def require_role!(*roles)
        return if roles.include?(current_role)

        render json: { error: "Role #{current_role} is not allowed to perform this action" }, status: :forbidden
      end

      def role_allowed?(*roles)
        require_role!(*roles)
        !performed?
      end

      def audit!(action, record, metadata = {})
        AuditLog.create!(
          actor: current_actor,
          role: current_role,
          action:,
          auditable_type: record.class.name,
          auditable_id: record.id,
          metadata:
        )
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
        return token if scheme&.casecmp("Bearer")&.zero?
      end

      def service_principal(token)
        account = ServiceAccount.authenticate_bearer(token)
        return unless account

        AuthenticatedPrincipal.new(actor: account.identifier, role: account.role, kind: "service", record: account)
      end

      def render_unprocessable_entity(error)
        message = error.respond_to?(:record) ? error.record.errors.full_messages : [error.message]
        render json: { errors: message }, status: :unprocessable_entity
      end

      def render_not_found
        render json: { error: "Record not found" }, status: :not_found
      end
    end
  end
end
