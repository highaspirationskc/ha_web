class EventRegistration < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :event_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :registration_date, presence: true
end
