class Medication < ApplicationRecord
  FORMS = ["tablet", "capsule", "injection solution", "oral solution", "inhalation", "cream"].freeze

  belongs_to :healthcare_unit
  has_many :order_lines, dependent: :restrict_with_error

  validates :name, :atc_code, :form, :strength, presence: true
  validates :inventory_balance, :minimum_threshold, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :form, inclusion: { in: FORMS }

  before_validation :assign_category

  scope :search, ->(query) {
    return all if query.blank?

    where("name ILIKE :query OR atc_code ILIKE :query OR form ILIKE :query", query: "%#{sanitize_sql_like(query)}%")
  }

  scope :by_form, ->(form) {
    return all if form.blank?

    where(form:)
  }

  def low_inventory?
    inventory_balance < minimum_threshold
  end

  private

  def assign_category
    self.category = MedicationCategorizer.call(name:, atc_code:)
  end
end
