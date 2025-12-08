class Mentee < ApplicationRecord
  belongs_to :user
  belongs_to :mentor, optional: true
  belongs_to :team, optional: true

  has_many :family_members, dependent: :destroy
  has_many :guardians, through: :family_members
end
