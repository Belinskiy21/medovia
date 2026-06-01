require "csv"

module Api
  module V1
    class OrdersController < BaseController
      before_action :set_unit, only: [:index, :create, :export]

      def index
        orders = @unit.orders.includes(order_lines: :medication).order(created_at: :desc)
        render json: orders.map { |order| OrderSerializer.render(order) }
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
        orders = @unit.orders.includes(order_lines: :medication).order(created_at: :desc)
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
    end
  end
end
