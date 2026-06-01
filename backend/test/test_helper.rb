ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def auth_headers(role: "pharmacist", email: nil)
      user = User.create!(
        email: email || "#{role}-#{SecureRandom.hex(4)}@example.test",
        name: "#{role.capitalize} Test User",
        role:,
        password: "Password123!",
        password_confirmation: "Password123!"
      )

      { "Authorization" => "Bearer #{AuthToken.issue(user)}" }
    end
  end
end
