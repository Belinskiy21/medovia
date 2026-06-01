require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "creates a user session token" do
    User.create!(
      email: "login@example.test",
      name: "Login User",
      role: "admin",
      password: "AdminPass123!",
      password_confirmation: "AdminPass123!"
    )

    post api_v1_session_path,
      params: {
        session: {
          email: "login@example.test",
          password: "AdminPass123!"
        }
      }

    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal "admin", body.dig("user", "role")
  end

  test "allows service account bearer token requests" do
    token = "svc_test_inventory_token"
    ServiceAccount.create!(
      identifier: "inventory-service@example.test",
      name: "Inventory Service",
      role: "pharmacist",
      token:,
      token_confirmation: token
    )
    unit = HealthcareUnit.create!(name: "Service Ward", location: "Stockholm")

    get api_v1_healthcare_unit_medications_path(unit),
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
  end
end
