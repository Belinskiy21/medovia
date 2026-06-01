class Order < ApplicationRecord
  STATUSES = ["draft", "sent", "confirmed", "delivered"].freeze

  belongs_to :healthcare_unit
  has_many :order_lines, dependent: :destroy
  accepts_nested_attributes_for :order_lines

  validates :status, inclusion: { in: STATUSES }
  validates :created_by, presence: true
  validate :must_have_lines

  def advance!
    next_status = STATUSES[STATUSES.index(status) + 1]
    raise ArgumentError, "Order is already delivered" if next_status.blank?

    transaction do
      update!(status: next_status, timestamp_column(next_status) => Time.current)
      apply_delivery! if next_status == "delivered"
    end
  end

  private

  def must_have_lines
    errors.add(:order_lines, "must contain at least one medication") if order_lines.empty?
  end

  def timestamp_column(status)
    "#{status}_at"
  end

  def apply_delivery!
    order_lines.includes(:medication).find_each do |line|
      line.medication.increment!(:inventory_balance, line.quantity)
    end
  end
end
