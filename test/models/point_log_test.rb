require "test_helper"

class PointLogTest < ActiveSupport::TestCase
  def setup
    @mentee_user = User.create!(
      email: "mentee@example.com",
      password: "Password123!"
    )
    @mentee = Mentee.create!(user: @mentee_user)

    @staff_user = User.create!(
      email: "staff@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @staff_user)
  end

  # Associations
  test "belongs to mentee" do
    point_log = PointLog.new(mentee: @mentee, points: 10, reason: "Test", awarded_by: @staff_user, log_type: "adjustment")
    assert_respond_to point_log, :mentee
    assert_equal @mentee, point_log.mentee
  end

  test "belongs to awarded_by (User)" do
    point_log = PointLog.new(mentee: @mentee, points: 10, reason: "Test", awarded_by: @staff_user, log_type: "adjustment")
    assert_respond_to point_log, :awarded_by
    assert_equal @staff_user, point_log.awarded_by
  end

  # Validations
  test "is valid with all required attributes" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Test reason",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  test "is invalid without a mentee" do
    point_log = PointLog.new(
      mentee: nil,
      points: 10,
      reason: "Test reason",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert_not point_log.valid?
    assert_includes point_log.errors[:mentee], "must exist"
  end

  test "is invalid without points" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: nil,
      reason: "Test reason",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert_not point_log.valid?
    assert_includes point_log.errors[:points], "can't be blank"
  end

  test "is invalid without a reason" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: nil,
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert_not point_log.valid?
    assert_includes point_log.errors[:reason], "can't be blank"
  end

  test "is valid without an awarded_by" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Test reason",
      awarded_by: nil,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  test "is invalid without a log_type" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Test reason",
      awarded_by: @staff_user,
      log_type: nil
    )
    assert_not point_log.valid?
    assert_includes point_log.errors[:log_type], "can't be blank"
  end

  test "is invalid with an invalid log_type" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Test reason",
      awarded_by: @staff_user,
      log_type: "invalid_type"
    )
    assert_not point_log.valid?
    assert_includes point_log.errors[:log_type], "is not included in the list"
  end

  # Log types
  test "accepts 'attendance' as log_type" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 5,
      reason: "Event attendance",
      awarded_by: @staff_user,
      log_type: "attendance"
    )
    assert point_log.valid?
  end

  test "accepts 'redemption' as log_type" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: -20,
      reason: "Incentive redemption",
      awarded_by: @staff_user,
      log_type: "redemption"
    )
    assert point_log.valid?
  end

  test "accepts 'adjustment' as log_type" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 15,
      reason: "Manual adjustment",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  # Points can be positive or negative
  test "accepts positive points" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 100,
      reason: "Bonus points",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  test "accepts negative points" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: -50,
      reason: "Point deduction",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  test "accepts zero points" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 0,
      reason: "No change",
      awarded_by: @staff_user,
      log_type: "adjustment"
    )
    assert point_log.valid?
  end

  # Polymorphic source association
  test "can have a polymorphic source" do
    event_type = EventType.create!(name: "Test Event", category: "org", point_value: 10)
    event = Event.create!(name: "Test", event_date: Time.current, event_type: event_type, created_by: @staff_user)
    event_log = EventLog.create!(user: @mentee_user, event: event, points_awarded: 10, log_type: "arrived")

    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Event attendance",
      awarded_by: @staff_user,
      log_type: "attendance",
      source: event_log
    )

    assert point_log.valid?
    assert_equal event_log, point_log.source
  end

  test "source is optional" do
    point_log = PointLog.new(
      mentee: @mentee,
      points: 10,
      reason: "Manual adjustment",
      awarded_by: @staff_user,
      log_type: "adjustment",
      source: nil
    )
    assert point_log.valid?
  end

  # Scopes and class methods
  test "ordered by created_at descending by default" do
    PointLog.create!(mentee: @mentee, points: 10, reason: "First", awarded_by: @staff_user, log_type: "adjustment", created_at: 2.hours.ago)
    PointLog.create!(mentee: @mentee, points: 20, reason: "Second", awarded_by: @staff_user, log_type: "adjustment", created_at: 1.hour.ago)
    PointLog.create!(mentee: @mentee, points: 30, reason: "Third", awarded_by: @staff_user, log_type: "adjustment", created_at: Time.current)

    logs = @mentee.point_logs.to_a
    assert_equal [30, 20, 10], logs.map(&:points)
  end
end
