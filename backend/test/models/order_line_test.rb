require "test_helper"

class OrderLineTest < ActiveSupport::TestCase
  test "order lines cannot be changed after an order leaves draft" do
    unit = HealthcareUnit.create!(name: "Immutable Ward", location: "Stockholm")
    medication = unit.medications.create!(
      name: "Metoprolol",
      atc_code: "C07AB02",
      form: "tablet",
      strength: "50 mg",
      inventory_balance: 10,
      minimum_threshold: 5
    )
    order = unit.orders.create!(
      created_by: "nurse@example.test",
      order_lines_attributes: [
        { medication:, quantity: 4 }
      ]
    )

    order.advance!
    line = order.order_lines.first
    line.quantity = 8

    assert_not line.valid?
    assert_includes line.errors.full_messages, "Order history cannot be changed after an order leaves draft"
  end
end
