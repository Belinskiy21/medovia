require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "supports the seeded healthcare roles with secure passwords" do
    user = User.create!(
      email: "reviewer@example.test",
      name: "Reviewer",
      password: "PharmacistPass123!",
      password_confirmation: "PharmacistPass123!"
    )
    unit = HealthcareUnit.create!(name: "Role Ward", location: "Stockholm")
    membership = user.memberships.create!(healthcare_unit: unit, role: "pharmacist")

    assert user.valid?
    assert user.authenticate("PharmacistPass123!")
    assert_equal membership.role, user.role_for(unit)
  end

  test "rejects unknown roles" do
    user = User.create!(email: "unknown@example.test", name: "Unknown", password: "Password123!", password_confirmation: "Password123!")
    unit = HealthcareUnit.create!(name: "Unknown Role Ward", location: "Stockholm")
    membership = user.memberships.new(healthcare_unit: unit, role: "doctor")

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end
end
