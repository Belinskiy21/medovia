module Api
  module V1
    class AuditLogsController < BaseController
      def index
        return unless role_allowed?("admin")

        logs = AuditLog.order(created_at: :desc).limit(100)
        render json: logs.map { |log| AuditLogSerializer.render(log) }
      end
    end
  end
end
