class Incentive < ApplicationRecord
  belongs_to :image, class_name: "Medium", optional: true
  belongs_to :created_by, class_name: "User"

  has_many :redemptions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :point_cost, presence: true, numericality: { greater_than: 0 }
  validates :incentive_type, presence: true, inclusion: { in: %w[individual team] }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :individual, -> { where(incentive_type: "individual") }
  scope :team, -> { where(incentive_type: "team") }

  def individual?
    incentive_type == "individual"
  end

  def team?
    incentive_type == "team"
  end
end
