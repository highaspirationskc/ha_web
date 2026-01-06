require "test_helper"

class ApplicationControllerSeasonTest < ActionDispatch::IntegrationTest
  def setup
    @staff_user = create_staff_user

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

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Tests for current_season_year with year-spanning seasons
  test "current_season_year returns previous year when in winter season that started last year" do
    login_as(@staff_user)

    # January 15, 2026 is in Winter season that started Dec 2025
    travel_to Date.new(2026, 1, 15) do
      get dashboard_path
      assert_response :success

      # Should be 2025 (when Winter started), not 2026
      assert_equal 2025, @controller.send(:current_season_year)
      assert_equal @winter, @controller.send(:current_season)
      assert_not @controller.send(:viewing_different_season?)
    end
  end

  test "current_season_year returns current year when in December of year-spanning season" do
    login_as(@staff_user)

    # December 15, 2025 is in Winter 2025 (Dec 2025 - Feb 2026)
    travel_to Date.new(2025, 12, 15) do
      get dashboard_path
      assert_response :success

      assert_equal 2025, @controller.send(:current_season_year)
      assert_equal @winter, @controller.send(:current_season)
      assert_not @controller.send(:viewing_different_season?)
    end
  end

  test "current_season_year returns current year for non-spanning season" do
    login_as(@staff_user)

    # July 15, 2025 is in Summer season (Jun-Aug, same year)
    travel_to Date.new(2025, 7, 15) do
      get dashboard_path
      assert_response :success

      assert_equal 2025, @controller.send(:current_season_year)
      assert_equal @summer, @controller.send(:current_season)
      assert_not @controller.send(:viewing_different_season?)
    end
  end

  # Tests for viewing_different_season?
  test "viewing_different_season returns true when viewing a different season" do
    login_as(@staff_user)

    travel_to Date.new(2025, 7, 15) do
      # Select Winter 2024 while in Summer 2025
      patch season_path, params: { id: @winter.id, year: 2024 }

      get dashboard_path
      assert_response :success

      assert @controller.send(:viewing_different_season?)
      assert_equal 2024, @controller.send(:current_season_year)
      assert_equal @winter, @controller.send(:current_season)
    end
  end

  test "viewing_different_season returns false after resetting to current season" do
    login_as(@staff_user)

    travel_to Date.new(2025, 7, 15) do
      # Select a different season
      patch season_path, params: { id: @winter.id, year: 2024 }

      # Reset to current
      delete reset_season_path

      get dashboard_path
      assert_response :success

      assert_not @controller.send(:viewing_different_season?)
      assert_equal @summer, @controller.send(:current_season)
    end
  end

  # Tests for formatted_season_range
  test "formatted_season_range shows correct range for non-spanning season" do
    login_as(@staff_user)

    travel_to Date.new(2025, 7, 15) do
      get dashboard_path
      assert_response :success

      range = @controller.send(:formatted_season_range)
      assert_equal "Summer Jun 1, 2025 - Aug 31, 2025", range
    end
  end

  test "formatted_season_range shows correct range for year-spanning season" do
    login_as(@staff_user)

    travel_to Date.new(2026, 1, 15) do
      get dashboard_path
      assert_response :success

      range = @controller.send(:formatted_season_range)
      assert_equal "Winter Dec 1, 2025 - Feb 28, 2026", range
    end
  end

  test "formatted_season_range shows correct range when manually selecting a season" do
    login_as(@staff_user)

    travel_to Date.new(2025, 7, 15) do
      # Select Winter 2024
      patch season_path, params: { id: @winter.id, year: 2024 }

      get dashboard_path
      assert_response :success

      range = @controller.send(:formatted_season_range)
      assert_equal "Winter Dec 1, 2024 - Feb 28, 2025", range
    end
  end
end
