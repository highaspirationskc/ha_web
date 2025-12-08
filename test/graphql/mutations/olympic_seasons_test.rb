# frozen_string_literal: true

require "test_helper"

class OlympicSeasonsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_admin_user(email: "admin@example.com")

    @olympic_season = OlympicSeason.create!(
      name: "Summer 2024",
      start_month: 6,
      start_day: 1,
      end_month: 8,
      end_day: 31
    )
  end

  # CreateOlympicSeason tests

  test "authenticated user can create olympic season" do
    mutation = <<~GQL
      mutation($input: CreateOlympicSeasonInput!) {
        createOlympicSeason(input: $input) {
          olympicSeason {
            id
            name
            startMonth
            startDay
            endMonth
            endDay
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Winter 2024",
        startMonth: 12,
        startDay: 1,
        endMonth: 2,
        endDay: 28
      }
    }, context: { current_user: @admin })

    olympic_season = result.dig("data", "createOlympicSeason", "olympicSeason")
    errors = result.dig("data", "createOlympicSeason", "errors")

    assert_not_nil olympic_season
    assert_equal "Winter 2024", olympic_season["name"]
    assert_equal 12, olympic_season["startMonth"]
    assert_equal 1, olympic_season["startDay"]
    assert_equal 2, olympic_season["endMonth"]
    assert_equal 28, olympic_season["endDay"]
    assert_empty errors
  end

  test "create olympic season requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateOlympicSeasonInput!) {
        createOlympicSeason(input: $input) {
          olympicSeason {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Fall 2024",
        startMonth: 9,
        startDay: 1,
        endMonth: 11,
        endDay: 30
      }
    }, context: {})

    assert_nil result.dig("data", "createOlympicSeason")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateOlympicSeason tests

  test "authenticated user can update olympic season" do
    mutation = <<~GQL
      mutation($input: UpdateOlympicSeasonInput!) {
        updateOlympicSeason(input: $input) {
          olympicSeason {
            id
            name
            startMonth
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @olympic_season.id.to_s,
        name: "Updated Summer 2024",
        startMonth: 5
      }
    }, context: { current_user: @admin })

    olympic_season = result.dig("data", "updateOlympicSeason", "olympicSeason")
    errors = result.dig("data", "updateOlympicSeason", "errors")

    assert_not_nil olympic_season
    assert_equal "Updated Summer 2024", olympic_season["name"]
    assert_equal 5, olympic_season["startMonth"]
    assert_empty errors
  end

  test "update olympic season returns error for non-existent season" do
    mutation = <<~GQL
      mutation($input: UpdateOlympicSeasonInput!) {
        updateOlympicSeason(input: $input) {
          olympicSeason {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        name: "Ghost Season"
      }
    }, context: { current_user: @admin })

    olympic_season = result.dig("data", "updateOlympicSeason", "olympicSeason")
    errors = result.dig("data", "updateOlympicSeason", "errors")

    assert_nil olympic_season
    assert_includes errors, "Olympic season not found"
  end

  # DeleteOlympicSeason tests

  test "authenticated user can delete olympic season" do
    season_to_delete = OlympicSeason.create!(
      name: "Delete Me",
      start_month: 3,
      start_day: 1,
      end_month: 5,
      end_day: 31
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteOlympicSeason(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: season_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteOlympicSeason", "success")
    errors = result.dig("data", "deleteOlympicSeason", "errors")

    assert success
    assert_empty errors
    assert_nil OlympicSeason.find_by(id: season_to_delete.id)
  end

  test "delete olympic season returns error for non-existent season" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteOlympicSeason(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteOlympicSeason", "success")
    errors = result.dig("data", "deleteOlympicSeason", "errors")

    assert_not success
    assert_includes errors, "Olympic season not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
