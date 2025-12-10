require "test_helper"

class CommunityServiceRecordTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "mentee@example.com",
      password: "Password123!"
    )
    @team = Team.create!(name: "Test Team", color: "blue")
    @mentee = Mentee.create!(user: @user, team: @team)

    @record = CommunityServiceRecord.new(
      mentee: @mentee,
      event: "Mowed lawn",
      description: "Helped neighbor with yard work",
      event_date: Date.current,
      hours: 2.5
    )
  end

  # Associations
  test "belongs to mentee" do
    assert_respond_to @record, :mentee
    assert_equal @mentee, @record.mentee
  end

  # Validations
  test "is valid with all required attributes" do
    assert @record.valid?
  end

  test "is invalid without a mentee" do
    @record.mentee = nil
    assert_not @record.valid?
    assert_includes @record.errors[:mentee], "must exist"
  end

  test "is invalid without an event" do
    @record.event = nil
    assert_not @record.valid?
    assert_includes @record.errors[:event], "can't be blank"
  end

  test "is invalid with blank event" do
    @record.event = ""
    assert_not @record.valid?
    assert_includes @record.errors[:event], "can't be blank"
  end

  test "is invalid without event_date" do
    @record.event_date = nil
    assert_not @record.valid?
    assert_includes @record.errors[:event_date], "can't be blank"
  end

  test "is invalid without hours" do
    @record.hours = nil
    assert_not @record.valid?
    assert_includes @record.errors[:hours], "can't be blank"
  end

  test "is invalid with zero hours" do
    @record.hours = 0
    assert_not @record.valid?
    assert_includes @record.errors[:hours], "must be greater than 0"
  end

  test "is invalid with negative hours" do
    @record.hours = -1
    assert_not @record.valid?
    assert_includes @record.errors[:hours], "must be greater than 0"
  end

  test "is valid with positive hours" do
    @record.hours = 0.5
    assert @record.valid?
  end

  test "is valid without description" do
    @record.description = nil
    assert @record.valid?
  end

  # Default values
  test "approved defaults to true" do
    @record.save!
    assert @record.approved?
  end

  # Scopes
  test "approved scope returns only approved records" do
    @record.save!
    denied_record = CommunityServiceRecord.create!(
      mentee: @mentee,
      event: "Denied event",
      event_date: Date.current,
      hours: 1,
      approved: false
    )

    assert_includes CommunityServiceRecord.approved, @record
    assert_not_includes CommunityServiceRecord.approved, denied_record
  end

  test "denied scope returns only denied records" do
    @record.save!
    denied_record = CommunityServiceRecord.create!(
      mentee: @mentee,
      event: "Denied event",
      event_date: Date.current,
      hours: 1,
      approved: false
    )

    assert_not_includes CommunityServiceRecord.denied, @record
    assert_includes CommunityServiceRecord.denied, denied_record
  end

  # Decimal hours
  test "supports decimal hours" do
    @record.hours = 2.75
    @record.save!
    @record.reload
    assert_equal 2.75, @record.hours.to_f
  end
end
