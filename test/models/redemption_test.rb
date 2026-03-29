require "test_helper"

class RedemptionTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "redemption_admin@example.com")
    @mentee_user = create_mentee_user(email: "redemption_mentee@example.com")
    @mentee = @mentee_user.mentee
    @incentive = Incentive.create!(
      name: "Jack Stack Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )
    @redemption = Redemption.new(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )
  end

  # Validations
  test "is valid with all required attributes" do
    assert @redemption.valid?
  end

  test "is invalid without a mentee" do
    @redemption.mentee = nil
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:mentee], "must exist"
  end

  test "is invalid without an incentive" do
    @redemption.incentive = nil
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:incentive], "must exist"
  end

  test "is invalid without points_spent" do
    @redemption.points_spent = nil
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:points_spent], "can't be blank"
  end

  test "is invalid with zero points_spent" do
    @redemption.points_spent = 0
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:points_spent], "must be greater than 0"
  end

  test "is invalid with negative points_spent" do
    @redemption.points_spent = -5
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:points_spent], "must be greater than 0"
  end

  test "is invalid without a status" do
    @redemption.status = nil
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:status], "can't be blank"
  end

  test "is invalid with unrecognized status" do
    @redemption.status = "unknown"
    assert_not @redemption.valid?
    assert_includes @redemption.errors[:status], "is not included in the list"
  end

  test "accepts all valid statuses" do
    %w[pending approved denied deleted deleted_no_refund].each do |status|
      @redemption.status = status
      assert @redemption.valid?, "Expected status '#{status}' to be valid"
    end
  end

  # Defaults
  test "defaults status to pending" do
    redemption = Redemption.new
    assert_equal "pending", redemption.status
  end

  # Optional fields
  test "is valid without approved_by" do
    @redemption.approved_by = nil
    assert @redemption.valid?
  end

  test "is valid without notes" do
    @redemption.notes = nil
    assert @redemption.valid?
  end

  # Associations
  test "belongs to mentee" do
    @redemption.save!
    assert_equal @mentee, @redemption.mentee
  end

  test "belongs to incentive" do
    @redemption.save!
    assert_equal @incentive, @redemption.incentive
  end

  test "belongs to approved_by user" do
    @redemption.approved_by = @admin
    @redemption.save!
    assert_equal @admin, @redemption.approved_by
  end

  # Scopes
  test "pending scope returns only pending redemptions" do
    pending = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "pending")
    approved = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "approved")

    assert_includes Redemption.pending, pending
    assert_not_includes Redemption.pending, approved
  end

  test "approved scope returns only approved redemptions" do
    pending = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "pending")
    approved = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "approved")

    assert_not_includes Redemption.approved, pending
    assert_includes Redemption.approved, approved
  end

  test "denied scope returns only denied redemptions" do
    pending = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "pending")
    denied = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "denied")

    assert_not_includes Redemption.denied, pending
    assert_includes Redemption.denied, denied
  end

  test "active scope returns pending, approved, and deleted_no_refund" do
    pending = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "pending")
    approved = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "approved")
    denied = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "denied")
    deleted = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "deleted")
    deleted_no_refund = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "deleted_no_refund")

    active = Redemption.active
    assert_includes active, pending
    assert_includes active, approved
    assert_not_includes active, denied
    assert_not_includes active, deleted
    assert_includes active, deleted_no_refund
  end

  test "visible scope returns pending and approved only" do
    pending = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "pending")
    approved = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "approved")
    denied = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "denied")
    deleted = Redemption.create!(mentee: @mentee, incentive: @incentive, points_spent: 25, status: "deleted")

    visible = Redemption.visible
    assert_includes visible, pending
    assert_includes visible, approved
    assert_not_includes visible, denied
    assert_not_includes visible, deleted
  end

  # Helper methods
  test "pending? returns true for pending status" do
    @redemption.status = "pending"
    assert @redemption.pending?
  end

  test "pending? returns false for other statuses" do
    @redemption.status = "approved"
    assert_not @redemption.pending?
  end

  test "approved? returns true for approved status" do
    @redemption.status = "approved"
    assert @redemption.approved?
  end

  test "approved? returns false for other statuses" do
    @redemption.status = "pending"
    assert_not @redemption.approved?
  end

  test "denied? returns true for denied status" do
    @redemption.status = "denied"
    assert @redemption.denied?
  end

  test "denied? returns false for other statuses" do
    @redemption.status = "pending"
    assert_not @redemption.denied?
  end

  test "deleted? returns true for deleted status" do
    @redemption.status = "deleted"
    assert @redemption.deleted?
  end

  test "deleted? returns false for other statuses" do
    @redemption.status = "pending"
    assert_not @redemption.deleted?
  end

  # Association from mentee side
  test "mentee has many redemptions" do
    @redemption.save!
    assert_includes @mentee.redemptions, @redemption
  end

  test "destroying mentee destroys redemptions" do
    @redemption.save!
    assert_difference "Redemption.count", -1 do
      @mentee.destroy!
    end
  end

  # Association from incentive side
  test "incentive has many redemptions" do
    @redemption.save!
    assert_includes @incentive.redemptions, @redemption
  end

  test "incentive with redemptions cannot be destroyed" do
    @redemption.save!
    assert_not @incentive.destroy
    assert_includes @incentive.errors[:base], "Cannot delete record because dependent redemptions exist"
  end
end
