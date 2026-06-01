class User < ApplicationRecord
  ROLES = Membership::ROLES

  has_secure_password
  has_many :memberships, dependent: :destroy
  has_many :healthcare_units, through: :memberships

  validates :email, :name, presence: true
  validates :email, uniqueness: true

  def role_for(healthcare_unit)
    memberships.find { |membership| membership.healthcare_unit_id == healthcare_unit.id }&.role ||
      memberships.find_by(healthcare_unit:)&.role
  end

  def role_in_unit?(healthcare_unit, *roles)
    memberships.exists?(healthcare_unit:, role: roles)
  end

  def role_in_any_unit?(*roles)
    memberships.exists?(role: roles)
  end
end
