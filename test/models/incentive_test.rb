require "test_helper"

class IncentiveTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "incentive_admin@example.com")
    @incentive = Incentive.new(
      name: "Jack Stack Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      active: true,
      created_by: @admin
    )
  end

  # Validations
  test "is valid with all required attributes" do
    assert @incentive.valid?
  end

  test "is invalid without a name" do
    @incentive.name = nil
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:name], "can't be blank"
  end

  test "is invalid without a point_cost" do
    @incentive.point_cost = nil
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:point_cost], "can't be blank"
  end

  test "is invalid with zero point_cost" do
    @incentive.point_cost = 0
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:point_cost], "must be greater than 0"
  end

  test "is invalid with negative point_cost" do
    @incentive.point_cost = -5
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:point_cost], "must be greater than 0"
  end

  test "is invalid without an incentive_type" do
    @incentive.incentive_type = nil
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:incentive_type], "can't be blank"
  end

  test "is invalid with unrecognized incentive_type" do
    @incentive.incentive_type = "group"
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:incentive_type], "is not included in the list"
  end

  test "accepts individual incentive_type" do
    @incentive.incentive_type = "individual"
    assert @incentive.valid?
  end

  test "accepts team incentive_type" do
    @incentive.incentive_type = "team"
    assert @incentive.valid?
  end

  test "is invalid without a created_by user" do
    @incentive.created_by = nil
    assert_not @incentive.valid?
    assert_includes @incentive.errors[:created_by], "must exist"
  end

  # Optional fields
  test "is valid without a description" do
    @incentive.description = nil
    assert @incentive.valid?
  end

  test "is valid without an image" do
    @incentive.image = nil
    assert @incentive.valid?
  end

  # Defaults
  test "defaults active to true" do
    incentive = Incentive.new
    assert_equal true, incentive.active
  end

  test "defaults incentive_type to individual" do
    incentive = Incentive.new
    assert_equal "individual", incentive.incentive_type
  end

  # Scopes
  test "active scope returns only active incentives" do
    @incentive.save!
    inactive = Incentive.create!(name: "Inactive", point_cost: 50, incentive_type: "individual", active: false, created_by: @admin)

    assert_includes Incentive.active, @incentive
    assert_not_includes Incentive.active, inactive
  end

  test "inactive scope returns only inactive incentives" do
    @incentive.save!
    inactive = Incentive.create!(name: "Inactive", point_cost: 50, incentive_type: "individual", active: false, created_by: @admin)

    assert_not_includes Incentive.inactive, @incentive
    assert_includes Incentive.inactive, inactive
  end

  test "individual scope returns only individual incentives" do
    @incentive.save!
    team_incentive = Incentive.create!(name: "Team Dinner", point_cost: 5000, incentive_type: "team", created_by: @admin)

    assert_includes Incentive.individual, @incentive
    assert_not_includes Incentive.individual, team_incentive
  end

  test "team scope returns only team incentives" do
    @incentive.save!
    team_incentive = Incentive.create!(name: "Team Dinner", point_cost: 5000, incentive_type: "team", created_by: @admin)

    assert_not_includes Incentive.team, @incentive
    assert_includes Incentive.team, team_incentive
  end

  # Helper methods
  test "individual? returns true for individual incentives" do
    @incentive.incentive_type = "individual"
    assert @incentive.individual?
  end

  test "individual? returns false for team incentives" do
    @incentive.incentive_type = "team"
    assert_not @incentive.individual?
  end

  test "team? returns true for team incentives" do
    @incentive.incentive_type = "team"
    assert @incentive.team?
  end

  test "team? returns false for individual incentives" do
    @incentive.incentive_type = "individual"
    assert_not @incentive.team?
  end

  # Associations
  test "belongs to created_by user" do
    @incentive.save!
    assert_equal @admin, @incentive.created_by
  end

  test "belongs to image (optional)" do
    assert_respond_to @incentive, :image
  end
end
