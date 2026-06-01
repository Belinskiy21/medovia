require "test_helper"

class MeditrackFlowTest < ActionDispatch::IntegrationTest
  setup do
    @unit = HealthcareUnit.create!(name: "Test Ward", location: "Stockholm")
    @medication = @unit.medications.create!(
      name: "Furosemide",
      atc_code: "C03CA01",
      form: "injection solution",
      strength: "10 mg/ml",
      inventory_balance: 3,
      minimum_threshold: 5
    )
  end

  test "creates an order and updates inventory on delivery" do
    post api_v1_healthcare_unit_orders_path(@unit),
      params: {
        order: {
          order_lines_attributes: [
            { medication_id: @medication.id, quantity: 12 }
          ]
        }
      },
      headers: auth_headers(role: "nurse", email: "nurse@example.test")

    assert_response :created
    order = Order.last
    assert_equal "draft", order.status

    3.times do
      patch advance_api_v1_order_path(order), headers: auth_headers(role: "pharmacist")
      assert_response :success
      order.reload
    end

    assert_equal "delivered", order.status
    assert_equal 15, @medication.reload.inventory_balance
  end

  test "lists medications with search and low inventory flag" do
    get api_v1_healthcare_unit_medications_path(@unit), params: { q: "C03" }, headers: auth_headers(role: "nurse")

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal true, body.first["low_inventory"]
  end

  test "rejects unauthenticated api requests" do
    get api_v1_healthcare_unit_medications_path(@unit), params: { q: "C03" }

    assert_response :unauthorized
  end
end
