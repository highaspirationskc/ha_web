class GradeCard < ApplicationRecord
  belongs_to :mentee
  belongs_to :medium

  scope :recent, -> { order(created_at: :desc) }
  scope :for_date_range, ->(range) { where(created_at: range) }

  delegate :url, :thumbnail_url, to: :medium

  after_destroy :cleanup_medium

  def mentee_user
    mentee.user
  end

  private

  def cleanup_medium
    return unless medium&.single_use?

    begin
      CloudflareImagesService.delete(medium.cloudflare_id)
    rescue CloudflareImagesService::DeleteError => e
      Rails.logger.warn("Failed to delete grade card image from Cloudflare: #{e.message}")
    end
    medium.destroy
  end
end
