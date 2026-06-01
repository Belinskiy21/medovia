require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "creates a user session token" do
    unit = HealthcareUnit.create!(name: "Login Ward", location: "Stockholm")
    user = User.create!(
      email: "login@example.test",
      name: "Login User",
      password: "AdminPass123!",
      password_confirmation: "AdminPass123!"
    )
    user.memberships.create!(healthcare_unit: unit, role: "admin")

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
    assert_equal "admin", body.dig("user", "memberships", 0, "role")
    assert_equal unit.id, body.dig("user", "memberships", 0, "healthcare_unit_id")
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

  test "scopes user access by healthcare unit membership" do
    allowed_unit = HealthcareUnit.create!(name: "Allowed Ward", location: "Stockholm")
    blocked_unit = HealthcareUnit.create!(name: "Blocked Ward", location: "Gothenburg")
    user = User.create!(
      email: "scoped@example.test",
      name: "Scoped User",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
    user.memberships.create!(healthcare_unit: allowed_unit, role: "nurse")
    headers = { "Authorization" => "Bearer #{AuthToken.issue(user)}" }

    get api_v1_healthcare_unit_medications_path(allowed_unit), headers: headers
    assert_response :success

    get api_v1_healthcare_unit_medications_path(blocked_unit), headers: headers
    assert_response :forbidden
  end
end
