module Api
  module V1
    class OrdersController < BaseController
      before_action :set_unit, only: [ :index, :create, :export ]

      def index
        return unless unit_access_allowed?(@unit)

        orders = filtered_orders
        paginated_orders, meta = paginate(orders.includes(order_lines: :medication), max_per_page: 100)

        render json: {
          data: paginated_orders.map { |order| OrderSerializer.render(order) },
          meta: meta.merge(
            open_count: orders.where.not(status: "delivered").count
          )
        }
      end

      def show
        order = Order.includes(order_lines: :medication).find(params[:id])
        return unless unit_access_allowed?(order.healthcare_unit)

        render json: OrderSerializer.render(order)
      end

      def create
        return unless role_allowed?("nurse", "pharmacist", "admin", healthcare_unit: @unit)

        order = @unit.orders.create!(order_params.merge(created_by: current_actor))
        audit!("order.created", order, line_count: order.order_lines.size)
        render json: OrderSerializer.render(order), status: :created
      end

      def advance
        order = Order.find(params[:id])
        return unless role_allowed?("pharmacist", "admin", healthcare_unit: order.healthcare_unit)

        previous_status = order.status
        order.advance!
        audit!("order.advanced", order, from: previous_status, to: order.status)
        render json: OrderSerializer.render(order.reload)
      end

      def export
        return unless unit_access_allowed?(@unit)

        orders = filtered_orders.includes(order_lines: :medication)

        send_data Orders::CsvExport.call(orders), filename: "meditrack-orders-unit-#{@unit.id}.csv", type: "text/csv"
      end

      private

      def set_unit
        @unit = HealthcareUnit.find(params[:healthcare_unit_id])
      end

      def order_params
        params.require(:order).permit(order_lines_attributes: [ :medication_id, :quantity ])
      end

      def filtered_orders
        orders = @unit.orders.order(created_at: :desc)
        orders = orders.where(status: params[:status]) if params[:status].present? && Order::STATUSES.include?(params[:status])
        orders = orders.where("created_by ILIKE ?", "%#{Order.sanitize_sql_like(params[:created_by])}%") if params[:created_by].present?
        orders = filter_created_at_range(orders)

        if params[:q].present?
          query = "%#{Order.sanitize_sql_like(params[:q])}%"
          orders = orders
            .joins(order_lines: :medication)
            .where("medications.name ILIKE :query OR medications.atc_code ILIKE :query", query:)
            .distinct
        end

        orders
      end
    end
  end
end
