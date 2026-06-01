require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "supports the seeded healthcare roles with secure passwords" do
    user = User.new(
      email: "reviewer@example.test",
      name: "Reviewer",
      role: "pharmacist",
      password: "PharmacistPass123!",
      password_confirmation: "PharmacistPass123!"
    )

    assert user.valid?
    assert user.authenticate("PharmacistPass123!")
  end

  test "rejects unknown roles" do
    user = User.new(
      email: "unknown@example.test",
      name: "Unknown",
      role: "doctor",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end
end
