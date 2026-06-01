class OrderLine < ApplicationRecord
  belongs_to :order
  belongs_to :medication

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validate :medication_matches_order_unit

  private

  def medication_matches_order_unit
    return if order.blank? || medication.blank?

    if medication.healthcare_unit_id != order.healthcare_unit_id
      errors.add(:medication, "must belong to the order healthcare unit")
    end
  end
end
