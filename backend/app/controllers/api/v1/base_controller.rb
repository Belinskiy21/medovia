module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ArgumentError, with: :render_unprocessable_entity

      private

      def current_actor
        request.headers.fetch("X-User-Email", "demo.nurse@medovia.test")
      end

      def current_role
        request.headers.fetch("X-User-Role", "nurse")
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
