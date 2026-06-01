class HealthcareUnit < ApplicationRecord
  has_many :medications, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, :location, presence: true
end
