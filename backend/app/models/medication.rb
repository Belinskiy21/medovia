class Medication < ApplicationRecord
  FORMS = ["tablet", "capsule", "injection solution", "oral solution", "inhalation", "cream"].freeze

  belongs_to :healthcare_unit
  has_many :order_lines, dependent: :restrict_with_error

  validates :name, :atc_code, :form, :strength, presence: true
  validates :inventory_balance, :minimum_threshold, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :form, inclusion: { in: FORMS }
  validate :unique_identity_in_healthcare_unit

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

  def unique_identity_in_healthcare_unit
    return if healthcare_unit_id.blank? || atc_code.blank? || form.blank? || strength.blank?

    duplicate = Medication
      .where(healthcare_unit_id:)
      .where("lower(atc_code) = ? AND lower(form) = ? AND lower(strength) = ?", atc_code.downcase, form.downcase, strength.downcase)
      .where.not(id:)
      .exists?

    errors.add(:atc_code, "has already been taken") if duplicate
  end
end
