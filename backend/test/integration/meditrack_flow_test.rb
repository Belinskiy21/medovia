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
    assert_equal 1, body["data"].length
    assert_equal 1, body["meta"]["total_count"]
    assert_equal true, body["data"].first["low_inventory"]
  end

  test "paginates medications" do
    12.times do |index|
      @unit.medications.create!(
        name: "Medication #{index}",
        atc_code: "A#{index.to_s.rjust(6, "0")}",
        form: "tablet",
        strength: "#{index + 1} mg",
        inventory_balance: 10,
        minimum_threshold: 5
      )
    end

    get api_v1_healthcare_unit_medications_path(@unit), params: { page: 2, per_page: 10 }, headers: auth_headers(role: "nurse")

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body["data"].length
    assert_equal 13, body["meta"]["total_count"]
    assert_equal 2, body["meta"]["page"]
    assert_equal 2, body["meta"]["total_pages"]
  end

  test "filters and paginates order history" do
    tablet = @unit.medications.create!(
      name: "Metoprolol",
      atc_code: "C07AB02",
      form: "tablet",
      strength: "50 mg",
      inventory_balance: 10,
      minimum_threshold: 5
    )
    12.times do |index|
      order = @unit.orders.create!(
        created_by: index.even? ? "nurse@example.test" : "pharmacist@example.test",
        created_at: Time.zone.local(2026, 6, index + 1, 10),
        order_lines_attributes: [
          { medication: index.even? ? @medication : tablet, quantity: index + 1 }
        ]
      )
      order.update!(status: "sent", sent_at: Time.current) if index.even?
    end

    get api_v1_healthcare_unit_orders_path(@unit),
      params: { q: "Furosemide", status: "sent", from: "2026-06-01", to: "2026-06-30", page: 1, per_page: 5 },
      headers: auth_headers(role: "nurse")

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 5, body["data"].length
    assert_equal 6, body["meta"]["total_count"]
    assert_equal 2, body["meta"]["total_pages"]
    assert_equal 6, body["meta"]["open_count"]
    assert body["data"].all? { |order| order["status"] == "sent" }
    assert body["data"].all? { |order| order["order_lines"].any? { |line| line["medication_name"] == "Furosemide" } }
  end

  test "rejects unauthenticated api requests" do
    get api_v1_healthcare_unit_medications_path(@unit), params: { q: "C03" }

    assert_response :unauthorized
  end
end
