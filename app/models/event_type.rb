class EventType < ApplicationRecord
  has_many :events, dependent: :destroy

  enum :category, { org: "org", user: "user" }

  validates :name, presence: true, uniqueness: true
  validates :point_value, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true
end
