class SeasDomain < ApplicationRecord
  has_many :seas_questions, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
end
