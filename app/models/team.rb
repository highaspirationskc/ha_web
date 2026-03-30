class Team < ApplicationRecord
  has_many :mentees, dependent: :nullify
  belongs_to :icon, class_name: "Medium", optional: true

  COLORS = %w[
    #E11D48 #F97316 #F59E0B #84CC16 #22C55E #10B981 #14B8A6 #06B6D4
    #0EA5E9 #3B82F6 #6366F1 #8B5CF6 #A855F7 #D946EF #EC4899 #F43F5E
    #F87171 #FB7185 #0F172A #64748B #7C2D12 #166534 #1E3A8A #0F766E #92400E
  ].freeze

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }

  after_destroy :cleanup_icon_medium

  def color_hex
    color
  end

  # Calculate total points for all mentees on this team for a given date range
  # Sums each mentee's individual total_points which uses the pointable scope
  # This ensures consistency with individual mentee calculations and properly
  # accounts for redemptions (excluding denied/deleted with refund)
  # Note: Acceptable N+1 since teams max at 10 mentees
  def total_points(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    mentees.sum { |mentee| mentee.total_points(date_range) }
  end

  # Calculate total approved community service hours for all mentees on this team
  def total_community_service_hours(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    CommunityServiceRecord
      .joins(:mentee)
      .where(mentees: { team_id: id })
      .where(approved: true)
      .where(event_date: date_range)
      .sum(:hours)
  end

  private

  def current_season_date_range
    current_season = OlympicSeason.current_season
    return nil unless current_season

    OlympicSeasonService.new(current_season).date_range_from_reference_date
  end

  def cleanup_icon_medium
    return unless icon&.single_use?

    begin
      CloudflareImagesService.delete(icon.cloudflare_id)
    rescue CloudflareImagesService::DeleteError => e
      Rails.logger.warn("Failed to delete icon from Cloudflare: #{e.message}")
    end
    icon.destroy
  end
end
