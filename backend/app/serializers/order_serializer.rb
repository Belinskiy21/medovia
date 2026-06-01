class OrderSerializer
  def self.render(order)
    {
      id: order.id,
      healthcare_unit_id: order.healthcare_unit_id,
      status: order.status,
      created_by: order.created_by,
      created_at: order.created_at,
      sent_at: order.sent_at,
      confirmed_at: order.confirmed_at,
      delivered_at: order.delivered_at,
      order_lines: order.order_lines.map do |line|
        {
          id: line.id,
          medication_id: line.medication_id,
          medication_name: line.medication.name,
          atc_code: line.medication.atc_code,
          quantity: line.quantity
        }
      end
    }
  end
end
