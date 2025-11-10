class Team < ApplicationRecord
  has_many :users, dependent: :nullify
  alias_method :members, :users
  has_many :mentees, -> { where(role: :mentee) }, class_name: "User"
  has_many :parents, -> { where(role: :parent) }, class_name: "User"
  has_many :mentors, -> { where(role: :mentor) }, class_name: "User"
  has_many :event_logs, through: :users

  enum :color, { blue: 0, green: 1, yellow: 2, red: 3 }

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true
end
