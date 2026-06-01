class Membership < ApplicationRecord
  ROLES = [ "nurse", "pharmacist", "admin" ].freeze

  belongs_to :user
  belongs_to :healthcare_unit

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :healthcare_unit_id, uniqueness: { scope: :user_id }
end
