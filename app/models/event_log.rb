class EventLog < ApplicationRecord
  belongs_to :event
  belongs_to :user
  has_one :point_log, as: :source, dependent: :destroy

  enum :log_type, { registered: "registered", arrived: "arrived" }

  before_validation :stamp_event_data, on: :create
  after_create :create_point_log_entry, if: :should_create_point_log?

  validates :event_id, presence: true
  validates :user_id, presence: true
  validates :log_type, presence: true
  validates :logged_at, presence: true
  validates :points_awarded, presence: true

  private

  def stamp_event_data
    return unless event

    # Auto-set points based on log_type (only mentees earn points)
    self.points_awarded ||= if log_type == "arrived" && user&.mentee?
      event.event_type.point_value
    else
      0
    end

    # Auto-set timestamp if not provided
    self.logged_at ||= Time.current
  end

  def should_create_point_log?
    log_type == "arrived" && user&.mentee? && points_awarded > 0
  end

  def create_point_log_entry
    return unless user&.mentee?

    PointLog.create!(
      mentee: user.mentee,
      points: points_awarded,
      reason: "Attended #{event.name} on #{event.event_date.strftime("%B %d, %Y")}",
      awarded_by: nil, # Automated attendance - no specific user
      log_type: "attendance",
      source: self
    )
  end
end
