class ServiceAccount < ApplicationRecord
  ROLES = User::ROLES

  has_secure_password :token

  validates :name, :identifier, :role, presence: true
  validates :identifier, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  def self.authenticate_bearer(raw_token)
    find_each.find { |account| account.authenticate_token(raw_token) }
  end
end
