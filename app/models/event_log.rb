class EventLog < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :event_id, presence: true
  validates :user_id, presence: true
  validates :participated_at, presence: true
  validates :points_awarded, presence: true
end
