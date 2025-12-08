class Mentor < ApplicationRecord
  belongs_to :user
  has_many :mentees, dependent: :nullify
end
