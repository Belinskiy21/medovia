class Membership < ApplicationRecord
  ROLES = [ "nurse", "pharmacist", "admin" ].freeze

  belongs_to :user
  belongs_to :healthcare_unit

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: [ :user_id, :healthcare_unit_id ] }
end
