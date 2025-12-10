class SaturdayScoop < ApplicationRecord
  belongs_to :image, class_name: "Medium", optional: true
  belongs_to :video, class_name: "Medium", optional: true
  belongs_to :created_by, class_name: "User"

  validates :title, presence: true
  validates :author, presence: true
  validate :image_must_be_image_type
  validate :video_must_be_video_type

  scope :published, -> { where(published: true).where("publish_on IS NULL OR publish_on <= ?", Date.current) }
  scope :unpublished, -> { where(published: false).or(where("publish_on > ?", Date.current)) }
  scope :recent, -> { order(publish_on: :desc, created_at: :desc) }

  def published_and_live?
    published? && (publish_on.nil? || publish_on <= Date.current)
  end

  private

  def image_must_be_image_type
    return unless image.present? && !image.image?
    errors.add(:image, "must be an image type")
  end

  def video_must_be_video_type
    return unless video.present? && !video.video?
    errors.add(:video, "must be a video type")
  end
end
