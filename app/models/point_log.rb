class PointLog < ApplicationRecord
  belongs_to :mentee
  belongs_to :awarded_by, class_name: "User", optional: true
  belongs_to :source, polymorphic: true, optional: true

  LOG_TYPES = %w[attendance redemption adjustment].freeze

  validates :points, presence: true, numericality: { only_integer: true }
  validates :reason, presence: true
  validates :log_type, presence: true, inclusion: { in: LOG_TYPES }
  validates :mentee, presence: true

  default_scope { order(created_at: :desc) }

  # Scope to exclude point logs from denied or deleted (with refund) redemptions
  # This ensures that when a redemption is denied or deleted with refund, the points
  # are effectively "restored" to the mentee's balance for calculation purposes
  scope :pointable, -> {
    # Subquery to find redemption IDs that should be excluded (denied or deleted)
    excluded_redemption_ids = Redemption.where(status: ["denied", "deleted"]).select(:id)

    # Exclude redemption logs where source is a denied/deleted redemption
    where.not(
      log_type: "redemption",
      source_type: "Redemption",
      source_id: excluded_redemption_ids
    )
  }

  # Badge color for UI based on log type
  def badge_color
    case log_type
    when "attendance"
      "green"
    when "redemption"
      "red"
    when "adjustment"
      "indigo"
    else
      "gray"
    end
  end

  # Display name for log type
  def log_type_display
    case log_type
    when "attendance"
      "Attendance"
    when "redemption"
      "Redemption"
    when "adjustment"
      "Adjustment"
    else
      log_type.titleize
    end
  end

  # Awarded by display name
  def awarded_by_display
    if log_type == "attendance" && source.is_a?(EventLog)
      "Attending"
    else
      awarded_by&.email || "System"
    end
  end
end
