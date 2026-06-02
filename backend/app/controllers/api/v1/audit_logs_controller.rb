module Api
  module V1
    class AuditLogsController < BaseController
      def index
        return unless any_role_allowed?("admin")

        logs = filtered_logs.order(created_at: :desc).limit(100)
        render json: logs.map { |log| AuditLogSerializer.render(log) }
      end

      private

      def filtered_logs
        logs = AuditLog.all
        logs = logs.where(action: params[:event]) if params[:event].present?
        logs = logs.where(auditable_type: params[:record_type]) if params[:record_type].present?
        logs = logs.where("actor ILIKE ?", "%#{AuditLog.sanitize_sql_like(params[:actor])}%") if params[:actor].present?
        logs = logs.where("metadata ->> 'healthcare_unit_id' = ?", params[:healthcare_unit_id].to_s) if params[:healthcare_unit_id].present?
        logs = filter_created_at_range(logs)

        logs
      end
    end
  end
end
