class Order < ApplicationRecord
  STATUSES = ["draft", "sent", "confirmed", "delivered"].freeze

  belongs_to :healthcare_unit
  has_many :order_lines, dependent: :destroy
  accepts_nested_attributes_for :order_lines

  validates :status, inclusion: { in: STATUSES }
  validates :created_by, presence: true
  validate :must_have_lines

  def advance!
    Orders::Advance.call(self)
  end

  def next_status
    STATUSES[STATUSES.index(status) + 1]
  end

  private

  def must_have_lines
    errors.add(:order_lines, "must contain at least one medication") if order_lines.empty?
  end
end
