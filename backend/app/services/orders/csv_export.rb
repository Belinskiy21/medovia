require "csv"

module Orders
  class CsvExport
    HEADERS = [ "Order ID", "Status", "Created by", "Created at", "Medication", "ATC code", "Quantity" ].freeze

    def self.call(orders)
      new(orders).call
    end

    def initialize(orders)
      @orders = orders
    end

    def call
      CSV.generate(headers: true) do |out|
        out << HEADERS
        orders.each do |order|
          order.order_lines.each do |line|
            out << [
              order.id,
              order.status,
              order.created_by,
              order.created_at.iso8601,
              line.medication.name,
              line.medication.atc_code,
              line.quantity
            ]
          end
        end
      end
    end

    private

    attr_reader :orders
  end
end
