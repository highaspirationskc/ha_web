class Token < ApplicationRecord
  belongs_to :user

  validates :token_hash, presence: true, uniqueness: true
end
