class Guardian < ApplicationRecord
  belongs_to :user

  has_many :family_members, dependent: :destroy
  has_many :children, through: :family_members, source: :mentee
end
