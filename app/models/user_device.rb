class UserDevice < ApplicationRecord
  belongs_to :user

  validates :fcm_token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: %w[ios android web] }

  scope :for_platform, ->(platform) { where(platform: platform) }
end
