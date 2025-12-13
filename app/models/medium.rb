class Medium < ApplicationRecord
  self.table_name = "media"

  CATEGORIES = %w[general avatar icon grade_card].freeze
  SINGLE_USE_CATEGORIES = %w[avatar icon grade_card].freeze

  belongs_to :uploaded_by, class_name: "User"

  has_many :events, foreign_key: :image_id, dependent: :nullify
  has_many :users_as_avatar, class_name: "User", foreign_key: :avatar_id, dependent: :nullify
  has_many :teams, foreign_key: :icon_id, dependent: :nullify
  has_many :saturday_scoops_as_image, class_name: "SaturdayScoop", foreign_key: :image_id, dependent: :nullify
  has_many :saturday_scoops_as_video, class_name: "SaturdayScoop", foreign_key: :video_id, dependent: :nullify
  has_one :grade_card, dependent: :nullify

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
  scope :grade_cards, -> { where(category: "grade_card") }
  scope :library, -> { where(category: "general") }

  def url(variant: "public")
    if video?
      CloudflareStreamService.url(cloudflare_id)
    else
      CloudflareImagesService.url(cloudflare_id, variant: variant)
    end
  end

  def thumbnail_url
    if video?
      CloudflareStreamService.thumbnail_url(cloudflare_id)
    else
      case category
      when "avatar" then url(variant: "avatar")
      when "icon" then url(variant: "icon")
      else url(variant: "thumbnail")
      end
    end
  end

  def embed_url
    return nil unless video?
    CloudflareStreamService.embed_url(cloudflare_id)
  end

  def image?
    media_type == "image"
  end

  def video?
    media_type == "video"
  end

  def single_use?
    SINGLE_USE_CATEGORIES.include?(category)
  end

  def in_use?
    usage.any?
  end

  def usage
    usages = []
    usages.concat(events.map { |e| { type: "Event", record: e, name: e.name } })
    usages.concat(users_as_avatar.map { |u| { type: "User", record: u, name: u.email } })
    usages.concat(teams.map { |t| { type: "Team", record: t, name: t.name } })
    usages.concat(saturday_scoops_as_image.map { |s| { type: "SaturdayScoop", record: s, name: s.title } })
    usages.concat(saturday_scoops_as_video.map { |s| { type: "SaturdayScoop", record: s, name: s.title } })
    usages << { type: "GradeCard", record: grade_card, name: "Grade Card for #{grade_card.mentee&.user&.email}" } if grade_card
    usages
  end

  def usage_count
    events.count + users_as_avatar.count + teams.count + saturday_scoops_as_image.count + saturday_scoops_as_video.count + (grade_card ? 1 : 0)
  end
end
