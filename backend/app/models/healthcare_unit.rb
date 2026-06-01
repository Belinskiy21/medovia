class HealthcareUnit < ApplicationRecord
  has_many :medications, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, :location, presence: true
  validate :unique_name_location

  private

  def unique_name_location
    return if name.blank? || location.blank?

    duplicate = HealthcareUnit
      .where("lower(name) = ? AND lower(location) = ?", name.downcase, location.downcase)
      .where.not(id:)
      .exists?

    errors.add(:name, "has already been taken") if duplicate
  end
end
