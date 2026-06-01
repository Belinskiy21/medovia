module Orders
  class Advance
    def self.call(order)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      order.with_lock do
        next_status = order.next_status
        raise ArgumentError, "Order is already delivered" if next_status.blank?

        order.update!(status: next_status, timestamp_column(next_status) => Time.current)
        apply_delivery! if next_status == "delivered"
        order
      end
    end

    private

    attr_reader :order

    def timestamp_column(status)
      "#{status}_at"
    end

    def apply_delivery!
      order.order_lines.includes(:medication).find_each do |line|
        line.medication.with_lock do
          line.medication.update!(inventory_balance: line.medication.inventory_balance + line.quantity)
        end
      end
    end
  end
end
