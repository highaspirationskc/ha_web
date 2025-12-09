class Medium < ApplicationRecord
  self.table_name = "media"

  CATEGORIES = %w[general avatar icon].freeze

  belongs_to :uploaded_by, class_name: "User"

  has_many :events, foreign_key: :image_id, dependent: :nullify
  has_many :users_as_avatar, class_name: "User", foreign_key: :avatar_id, dependent: :nullify
  has_many :teams, foreign_key: :icon_id, dependent: :nullify

  validates :cloudflare_id, presence: true, uniqueness: true
  validates :filename, presence: true
  validates :media_type, presence: true, inclusion: { in: %w[image video] }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :images, -> { where(media_type: "image") }
  scope :videos, -> { where(media_type: "video") }
  scope :by_user, ->(user) { where(uploaded_by: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :general, -> { where(category: "general") }
  scope :avatars, -> { where(category: "avatar") }
  scope :icons, -> { where(category: "icon") }

  def url(variant: "public")
    CloudflareImagesService.url(cloudflare_id, variant: variant)
  end

  def thumbnail_url
    case category
    when "avatar" then url(variant: "avatar")
    when "icon" then url(variant: "icon")
    else url(variant: "thumbnail")
    end
  end

  def image?
    media_type == "image"
  end

  def video?
    media_type == "video"
  end

  def in_use?
    usage.any?
  end

  def usage
    usages = []
    usages.concat(events.map { |e| { type: "Event", record: e, name: e.name } })
    usages.concat(users_as_avatar.map { |u| { type: "User", record: u, name: u.email } })
    usages.concat(teams.map { |t| { type: "Team", record: t, name: t.name } })
    usages
  end

  def usage_count
    events.count + users_as_avatar.count + teams.count
  end
end
