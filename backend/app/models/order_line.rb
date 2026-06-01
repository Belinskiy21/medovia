class OrderLine < ApplicationRecord
  belongs_to :order
  belongs_to :medication

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :medication_id, uniqueness: { scope: :order_id }
  validate :medication_matches_order_unit
  validate :immutable_after_order_is_sent, on: :update

  private

  def medication_matches_order_unit
    return if order.blank? || medication.blank?

    if medication.healthcare_unit_id != order.healthcare_unit_id
      errors.add(:medication, "must belong to the order healthcare unit")
    end
  end

  def immutable_after_order_is_sent
    return if order.blank? || order.status == "draft"

    errors.add(:base, "Order history cannot be changed after an order leaves draft")
  end
end
