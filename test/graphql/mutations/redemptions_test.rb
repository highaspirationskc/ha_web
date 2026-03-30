# frozen_string_literal: true

require "test_helper"

class RedemptionsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin_red_gql@example.com")
    @mentee_user = create_mentee_user(email: "mentee_red_gql@example.com")
    @mentee = @mentee_user.mentee
    @mentor_user = create_mentor_user(email: "mentor_red_gql@example.com")

    @incentive = Incentive.create!(
      name: "Jack Stack Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    # Give the mentee some points
    today = Date.current
    OlympicSeason.create!(
      name: "GQL Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "GQL Event Type", category: "org", point_value: 50)
    event = Event.create!(name: "GQL Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 50, log_type: "arrived")
  end

  CREATE_REDEMPTION = <<~GQL
    mutation($incentiveId: ID!) {
      createRedemption(incentiveId: $incentiveId) {
        redemption {
          id
          pointsSpent
          status
          incentive {
            id
            name
          }
        }
        errors
      }
    }
  GQL

  test "mentee can create a redemption" do
    result = execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: { current_user: @mentee_user })

    data = result.dig("data", "createRedemption")
    assert_not_nil data["redemption"]
    assert_equal "pending", data["redemption"]["status"]
    assert_equal 25, data["redemption"]["pointsSpent"]
    assert_equal @incentive.name, data["redemption"]["incentive"]["name"]
    assert_empty data["errors"]
  end

  test "creating a redemption deducts points" do
    assert_equal 50, @mentee.total_points

    execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: { current_user: @mentee_user })

    assert_equal 25, @mentee.total_points
  end

  test "cannot create redemption with insufficient points" do
    # Create a redemption that uses all points
    expensive_incentive = Incentive.create!(
      name: "Expensive Item",
      point_cost: 50,
      incentive_type: "individual",
      created_by: @admin
    )
    Redemption.create!(mentee: @mentee, incentive: expensive_incentive, points_spent: 50, status: "pending")

    # Try to create redemption for original incentive (25 points) - should fail with insufficient points
    result = execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: { current_user: @mentee_user })

    data = result.dig("data", "createRedemption")
    assert_nil data["redemption"]
    assert_includes data["errors"].first, "Not enough points"
  end

  test "non-mentee cannot create redemption" do
    result = execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: { current_user: @mentor_user })

    data = result.dig("data", "createRedemption")
    assert_nil data["redemption"]
    assert_includes data["errors"].first, "Only mentees can create redemptions"
  end

  test "unauthenticated user cannot create redemption" do
    result = execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: {})

    assert result["errors"].present?
  end

  test "cannot create redemption for inactive incentive" do
    @incentive.update!(active: false)

    result = execute_graphql(CREATE_REDEMPTION,
      variables: { incentiveId: @incentive.id.to_s },
      context: { current_user: @mentee_user })

    data = result.dig("data", "createRedemption")
    assert_nil data["redemption"]
    assert_includes data["errors"].first, "Incentive not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
