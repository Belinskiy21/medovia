class User < ApplicationRecord
  ROLES = ["nurse", "pharmacist", "admin"].freeze

  has_secure_password

  validates :email, :name, :role, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: ROLES }
end
