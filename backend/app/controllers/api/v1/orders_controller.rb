require "csv"

module Api
  module V1
    class OrdersController < BaseController
      before_action :set_unit, only: [:index, :create, :export]

      def index
        orders = filtered_orders
        total_count = orders.count
        page = page_param
        per_page = per_page_param
        paginated_orders = orders.includes(order_lines: :medication).offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: paginated_orders.map { |order| OrderSerializer.render(order) },
          meta: {
            page:,
            per_page:,
            total_count:,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      def show
        render json: OrderSerializer.render(Order.includes(order_lines: :medication).find(params[:id]))
      end

      def create
        order = @unit.orders.create!(order_params.merge(created_by: current_actor))
        audit!("order.created", order, line_count: order.order_lines.size)
        render json: OrderSerializer.render(order), status: :created
      end

      def advance
        return unless role_allowed?("pharmacist", "admin")

        order = Order.find(params[:id])
        previous_status = order.status
        order.advance!
        audit!("order.advanced", order, from: previous_status, to: order.status)
        render json: OrderSerializer.render(order.reload)
      end

      def export
        orders = filtered_orders.includes(order_lines: :medication)
        csv = CSV.generate(headers: true) do |out|
          out << ["Order ID", "Status", "Created by", "Created at", "Medication", "ATC code", "Quantity"]
          orders.each do |order|
            order.order_lines.each do |line|
              out << [order.id, order.status, order.created_by, order.created_at.iso8601, line.medication.name, line.medication.atc_code, line.quantity]
            end
          end
        end

        send_data csv, filename: "meditrack-orders-unit-#{@unit.id}.csv", type: "text/csv"
      end

      private

      def set_unit
        @unit = HealthcareUnit.find(params[:healthcare_unit_id])
      end

      def order_params
        params.require(:order).permit(order_lines_attributes: [:medication_id, :quantity])
      end

      def filtered_orders
        orders = @unit.orders.order(created_at: :desc)
        orders = orders.where(status: params[:status]) if params[:status].present? && Order::STATUSES.include?(params[:status])
        orders = orders.where("created_by ILIKE ?", "%#{Order.sanitize_sql_like(params[:created_by])}%") if params[:created_by].present?
        orders = orders.where(created_at: Time.zone.parse(params[:from])..) if params[:from].present?
        orders = orders.where(created_at: ..Time.zone.parse(params[:to]).end_of_day) if params[:to].present?

        if params[:q].present?
          query = "%#{Order.sanitize_sql_like(params[:q])}%"
          orders = orders
            .joins(order_lines: :medication)
            .where("medications.name ILIKE :query OR medications.atc_code ILIKE :query", query:)
            .distinct
        end

        orders
      end

      def page_param
        [params.fetch(:page, 1).to_i, 1].max
      end

      def per_page_param
        params.fetch(:per_page, 10).to_i.clamp(1, 100)
      end
    end
  end
end
