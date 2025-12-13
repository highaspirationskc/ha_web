class Team < ApplicationRecord
  has_many :mentees, dependent: :nullify
  belongs_to :icon, class_name: "Medium", optional: true

  enum :color, { blue: "blue", green: "green", yellow: "yellow", red: "red" }

  validates :name, presence: true, uniqueness: true
  validates :color, presence: true
  validate :color_must_be_available, on: :create

  after_destroy :cleanup_icon_medium

  def self.available_colors
    taken = pluck(:color)
    colors.keys - taken
  end

  def self.colors_available?
    available_colors.any?
  end

  # Calculate total points for all mentees on this team for a given date range
  # If no date_range is provided, calculates for the current Olympic season
  def total_points(date_range = nil)
    date_range ||= current_season_date_range
    return 0 unless date_range

    EventLog.joins(user: :mentee, event: {})
            .where(mentees: { team_id: id })
            .where(events: { event_date: date_range })
            .sum(:points_awarded)
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

  def color_must_be_available
    return if color.blank?

    taken_colors = Team.where.not(id: id).pluck(:color)
    if taken_colors.include?(color)
      errors.add(:color, "has already been taken")
    end
  end

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
