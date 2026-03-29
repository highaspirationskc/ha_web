# frozen_string_literal: true

require "test_helper"

class RewardsQueryTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin_rew_gql@example.com")
    @mentee_user = create_mentee_user(email: "mentee_rew_gql@example.com")
    @mentee = @mentee_user.mentee
    @mentor_user = create_mentor_user(email: "mentor_rew_gql@example.com")

    @individual_incentive = Incentive.create!(
      name: "Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    @team_incentive = Incentive.create!(
      name: "Team Pizza",
      description: "Pizza party",
      point_cost: 100,
      incentive_type: "team",
      created_by: @admin
    )

    @inactive_incentive = Incentive.create!(
      name: "Inactive Reward",
      point_cost: 10,
      incentive_type: "individual",
      active: false,
      created_by: @admin
    )

    # Give the mentee some points
    today = Date.current
    OlympicSeason.create!(
      name: "Rewards Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Rewards Event Type", category: "org", point_value: 50)
    event = Event.create!(name: "Rewards Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 50)

    # Create some redemptions
    @pending = Redemption.create!(mentee: @mentee, incentive: @individual_incentive, points_spent: 25, status: "pending")
    @approved = Redemption.create!(mentee: @mentee, incentive: @individual_incentive, points_spent: 25, status: "approved", approved_by: @admin)
    @denied = Redemption.create!(mentee: @mentee, incentive: @individual_incentive, points_spent: 25, status: "denied")
  end

  REWARDS_QUERY = <<~GQL
    {
      rewards {
        individualIncentives {
          id
          name
          pointCost
        }
        teamIncentives {
          id
          name
          pointCost
        }
        redeemed {
          id
          status
          pointsSpent
          incentive {
            name
          }
        }
        totalPoints
      }
    }
  GQL

  test "returns individual incentives" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentee_user })

    individual = result.dig("data", "rewards", "individualIncentives")
    assert_equal 1, individual.length
    assert_equal "Gift Card", individual.first["name"]
    assert_equal 25, individual.first["pointCost"]
  end

  test "returns team incentives" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentee_user })

    team = result.dig("data", "rewards", "teamIncentives")
    assert_equal 1, team.length
    assert_equal "Team Pizza", team.first["name"]
  end

  test "excludes inactive incentives" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentee_user })

    all_names = result.dig("data", "rewards", "individualIncentives").map { |i| i["name"] } +
                result.dig("data", "rewards", "teamIncentives").map { |i| i["name"] }
    assert_not_includes all_names, "Inactive Reward"
  end

  test "returns visible redemptions (pending and approved, not denied)" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentee_user })

    redeemed = result.dig("data", "rewards", "redeemed")
    statuses = redeemed.map { |r| r["status"] }
    assert_includes statuses, "pending"
    assert_includes statuses, "approved"
    assert_not_includes statuses, "denied"
  end

  test "returns total points with deductions" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentee_user })

    # 50 earned - 25 pending - 25 approved = 0
    assert_equal 0, result.dig("data", "rewards", "totalPoints")
  end

  test "requires authentication" do
    result = execute_graphql(REWARDS_QUERY, context: {})
    assert result["errors"].present?
  end

  test "requires mentee role" do
    result = execute_graphql(REWARDS_QUERY, context: { current_user: @mentor_user })
    assert result["errors"].present?
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
