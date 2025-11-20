require "test_helper"

class OlympicSeasonServiceTest < ActiveSupport::TestCase
  def setup
    # Create seasons for testing
    @summer = OlympicSeason.create!(
      name: "Summer",
      start_month: 6,
      start_day: 1,
      end_month: 8,
      end_day: 31
    )

    @winter = OlympicSeason.create!(
      name: "Winter",
      start_month: 12,
      start_day: 1,
      end_month: 2,
      end_day: 28
    )

    @fall = OlympicSeason.create!(
      name: "Fall",
      start_month: 9,
      start_day: 1,
      end_month: 11,
      end_day: 30
    )

    @spring = OlympicSeason.create!(
      name: "Spring",
      start_month: 3,
      start_day: 1,
      end_month: 5,
      end_day: 31
    )
  end

  # Test current_season class method
  test "finds current season" do
    # Travel to June 15, 2025 (Summer)
    travel_to Date.new(2025, 6, 15) do
      assert_equal @summer, OlympicSeasonService.current_season
    end

    # Travel to December 15, 2025 (Winter)
    travel_to Date.new(2025, 12, 15) do
      assert_equal @winter, OlympicSeasonService.current_season
    end

    # Travel to February 15, 2025 (Winter - spans years)
    travel_to Date.new(2025, 2, 15) do
      assert_equal @winter, OlympicSeasonService.current_season
    end
  end

  # Test includes_date? for regular season (within same year)
  test "includes_date? returns true for dates within summer season" do
    service = OlympicSeasonService.new(@summer)

    assert service.includes_date?(Date.new(2025, 6, 1))
    assert service.includes_date?(Date.new(2025, 7, 15))
    assert service.includes_date?(Date.new(2025, 8, 31))
  end

  test "includes_date? returns false for dates outside summer season" do
    service = OlympicSeasonService.new(@summer)

    assert_not service.includes_date?(Date.new(2025, 5, 31))
    assert_not service.includes_date?(Date.new(2025, 9, 1))
  end

  # Test includes_date? for season that spans years
  test "includes_date? returns true for dates within winter season (spans years)" do
    service = OlympicSeasonService.new(@winter)

    assert service.includes_date?(Date.new(2025, 12, 1))
    assert service.includes_date?(Date.new(2025, 12, 31))
    assert service.includes_date?(Date.new(2025, 1, 1))
    assert service.includes_date?(Date.new(2025, 2, 28))
  end

  test "includes_date? returns false for dates outside winter season" do
    service = OlympicSeasonService.new(@winter)

    assert_not service.includes_date?(Date.new(2025, 3, 1))
    assert_not service.includes_date?(Date.new(2025, 11, 30))
  end

  # Test date_range
  test "date_range returns correct range for summer season" do
    service = OlympicSeasonService.new(@summer)
    range = service.date_range(2025)

    assert_equal Date.new(2025, 6, 1), range.begin
    assert_equal Date.new(2025, 8, 31), range.end
  end

  test "date_range returns correct range for winter season (spans years)" do
    service = OlympicSeasonService.new(@winter)
    range = service.date_range(2025)

    assert_equal Date.new(2025, 12, 1), range.begin
    assert_equal Date.new(2026, 2, 28), range.end
  end

  # Test start_date and end_date
  test "start_date returns correct date for summer season" do
    service = OlympicSeasonService.new(@summer)
    assert_equal Date.new(2025, 6, 1), service.start_date(2025)
  end

  test "end_date returns correct date for summer season" do
    service = OlympicSeasonService.new(@summer)
    assert_equal Date.new(2025, 8, 31), service.end_date(2025)
  end

  test "end_date returns next year's date for winter season" do
    service = OlympicSeasonService.new(@winter)
    assert_equal Date.new(2026, 2, 28), service.end_date(2025)
  end

  # Test spans_years?
  test "spans_years? returns false for summer season" do
    service = OlympicSeasonService.new(@summer)
    assert_not service.spans_years?
  end

  test "spans_years? returns true for winter season" do
    service = OlympicSeasonService.new(@winter)
    assert service.spans_years?
  end

  # Test end_year
  test "end_year returns same year for summer season" do
    service = OlympicSeasonService.new(@summer)
    assert_equal 2025, service.end_year(2025)
  end

  test "end_year returns next year for winter season" do
    service = OlympicSeasonService.new(@winter)
    assert_equal 2026, service.end_year(2025)
  end

  # Test date_range_from_reference_date
  test "date_range_from_reference_date returns correct range for summer season" do
    service = OlympicSeasonService.new(@summer)
    range = service.date_range_from_reference_date(Date.new(2025, 7, 15))

    assert_equal Date.new(2025, 6, 1), range.begin
    assert_equal Date.new(2025, 8, 31), range.end
  end

  test "date_range_from_reference_date returns correct range for winter season (in December)" do
    service = OlympicSeasonService.new(@winter)
    range = service.date_range_from_reference_date(Date.new(2025, 12, 15))

    assert_equal Date.new(2025, 12, 1), range.begin
    assert_equal Date.new(2026, 2, 28), range.end
  end

  test "date_range_from_reference_date returns correct range for winter season (in February)" do
    service = OlympicSeasonService.new(@winter)
    range = service.date_range_from_reference_date(Date.new(2025, 2, 15))

    assert_equal Date.new(2024, 12, 1), range.begin
    assert_equal Date.new(2025, 2, 28), range.end
  end
end
