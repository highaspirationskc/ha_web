# frozen_string_literal: true

# Service object for Olympic Season date calculations and queries
class OlympicSeasonService
  attr_reader :season

  def initialize(season)
    @season = season
  end

  # Class method to find the current Olympic season
  def self.current_season
    today = Date.current
    OlympicSeason.all.find { |season| new(season).includes_date?(today) }
  end

  # Check if a given date falls within this season
  def includes_date?(date)
    month = date.month
    day = date.day

    if season.start_month <= season.end_month
      # Season within same year (e.g., March to August)
      (month > season.start_month || (month == season.start_month && day >= season.start_day)) &&
        (month < season.end_month || (month == season.end_month && day <= season.end_day))
    else
      # Season spans year boundary (e.g., November to February)
      (month > season.start_month || (month == season.start_month && day >= season.start_day)) ||
        (month < season.end_month || (month == season.end_month && day <= season.end_day))
    end
  end

  # Get the date range for this season in a specific year
  # Returns a Range of DateTime objects (start at beginning_of_day, end at end_of_day)
  def date_range(year = Date.current.year)
    start_date = Date.new(year, season.start_month, season.start_day).beginning_of_day
    end_date = Date.new(end_year(year), season.end_month, season.end_day).end_of_day
    start_date..end_date
  end

  # Get the start date for this season in a specific year
  def start_date(year = Date.current.year)
    Date.new(year, season.start_month, season.start_day)
  end

  # Get the end date for this season in a specific year
  def end_date(year = Date.current.year)
    Date.new(end_year(year), season.end_month, season.end_day)
  end

  # Determine if this season spans across calendar years
  def spans_years?
    season.start_month > season.end_month
  end

  # Get the year for the season's end date
  # If the season spans years (e.g., Dec-Feb), the end date is in the next year
  def end_year(start_year = Date.current.year)
    spans_years? ? start_year + 1 : start_year
  end

  # Get the date range for this season based on a reference date
  # Handles the case where we're in the middle of a season that spans years
  # Returns a Range of DateTime objects (start at beginning_of_day, end at end_of_day)
  def date_range_from_reference_date(reference_date = Date.current)
    year = reference_date.year

    if spans_years?
      if reference_date.month < season.start_month
        # We're in the end of the season (e.g., January/February)
        start_date = Date.new(year - 1, season.start_month, season.start_day)
        end_date = Date.new(year, season.end_month, season.end_day)
      else
        # We're in the start of the season (e.g., December)
        start_date = Date.new(year, season.start_month, season.start_day)
        end_date = Date.new(year + 1, season.end_month, season.end_day)
      end
    else
      start_date = Date.new(year, season.start_month, season.start_day)
      end_date = Date.new(year, season.end_month, season.end_day)
    end

    start_date.beginning_of_day..end_date.end_of_day
  end
end
