class EventLog < ApplicationRecord
  belongs_to :event
  belongs_to :user

  enum :log_type, { registered: 0, arrived: 1 }

  before_validation :stamp_event_data, on: :create

  validates :event_id, presence: true
  validates :user_id, presence: true
  validates :log_type, presence: true
  validates :logged_at, presence: true
  validates :points_awarded, presence: true

  private

  def stamp_event_data
    return unless event

    # Auto-set points based on log_type
    self.points_awarded ||= case log_type
    when "arrived"
      event.event_type.point_value
    when "registered"
      0
    else
      0
    end

    # Auto-set timestamp if not provided
    self.logged_at ||= Time.current
  end
end
