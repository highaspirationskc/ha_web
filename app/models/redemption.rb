class Redemption < ApplicationRecord
  STATUSES = %w[pending approved denied deleted deleted_no_refund].freeze

  belongs_to :mentee
  belongs_to :incentive
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :point_logs, as: :source, dependent: :destroy

  validates :points_spent, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :denied, -> { where(status: "denied") }
  # Active redemptions count toward points spent (pending, approved, and deleted_no_refund)
  # deleted redemptions (with refund) do NOT count toward points spent
  scope :active, -> { where(status: %w[pending approved deleted_no_refund]) }
  scope :visible, -> { where(status: %w[pending approved]) }

  # Create point log when redemption is created (pending or approved)
  after_create :create_deduction_point_log, if: :should_deduct_points?

  def pending? = status == "pending"
  def approved? = status == "approved"
  def denied? = status == "denied"
  def deleted? = status == "deleted"

  private

  def should_deduct_points?
    pending? || approved? || status == "deleted_no_refund"
  end

  def create_deduction_point_log
    PointLog.create!(
      mentee: mentee,
      points: -points_spent,
      reason: "Redeemed: #{incentive.name}",
      awarded_by: approved_by, # May be nil for pending redemptions
      log_type: "redemption",
      source: self
    )
  end
end
