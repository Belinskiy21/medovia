require "test_helper"

class DomainUniquenessTest < ActiveSupport::TestCase
  test "healthcare unit names are unique per location" do
    HealthcareUnit.create!(name: "Cardiology", location: "Stockholm")

    duplicate = HealthcareUnit.new(name: "cardiology", location: "stockholm")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "medication identity is unique inside a healthcare unit" do
    unit = HealthcareUnit.create!(name: "Medication Identity Ward", location: "Stockholm")
    unit.medications.create!(
      name: "Metoprolol",
      atc_code: "C07AB02",
      form: "tablet",
      strength: "50 mg",
      inventory_balance: 10,
      minimum_threshold: 5
    )

    duplicate = unit.medications.new(
      name: "Metoprolol depot",
      atc_code: "c07ab02",
      form: "tablet",
      strength: "50 MG",
      inventory_balance: 20,
      minimum_threshold: 5
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:atc_code], "has already been taken"
  end

  test "order can contain a medication only once" do
    unit = HealthcareUnit.create!(name: "Order Line Ward", location: "Stockholm")
    medication = unit.medications.create!(
      name: "Furosemide",
      atc_code: "C03CA01",
      form: "injection solution",
      strength: "10 mg/ml",
      inventory_balance: 10,
      minimum_threshold: 5
    )
    order = unit.orders.create!(
      created_by: "nurse@example.test",
      order_lines_attributes: [{ medication:, quantity: 4 }]
    )

    duplicate = order.order_lines.new(medication:, quantity: 2)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:medication_id], "has already been taken"
  end
end
