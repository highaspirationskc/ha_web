require "test_helper"

class GradeCardTest < ActiveSupport::TestCase
  def setup
    @admin = create_user
    @mentee_user = create_mentee_user(email: "mentee_gc@example.com")
    @mentee = @mentee_user.mentee

    @medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_test_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )

    @grade_card = GradeCard.new(
      mentee: @mentee,
      medium: @medium,
      description: "Fall 2025 grades"
    )
  end

  # Associations
  test "belongs to mentee" do
    assert_respond_to @grade_card, :mentee
    assert_equal @mentee, @grade_card.mentee
  end

  test "belongs to medium" do
    assert_respond_to @grade_card, :medium
    assert_equal @medium, @grade_card.medium
  end

  # Validations
  test "is valid with all required attributes" do
    assert @grade_card.valid?
  end

  test "is invalid without a mentee" do
    @grade_card.mentee = nil
    assert_not @grade_card.valid?
    assert_includes @grade_card.errors[:mentee], "must exist"
  end

  test "is invalid without a medium" do
    @grade_card.medium = nil
    assert_not @grade_card.valid?
    assert_includes @grade_card.errors[:medium], "must exist"
  end

  test "is valid without description" do
    @grade_card.description = nil
    assert @grade_card.valid?
  end

  # Scopes
  test "recent scope orders by created_at desc" do
    @grade_card.save!

    older_medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_older_#{SecureRandom.hex(8)}",
      filename: "older.jpg",
      media_type: "image",
      category: "grade_card"
    )
    older_card = GradeCard.create!(mentee: @mentee, medium: older_medium)
    older_card.update_column(:created_at, 1.week.ago)

    assert_equal [@grade_card, older_card], GradeCard.recent.to_a
  end

  test "for_date_range scope filters by created_at" do
    @grade_card.save!

    range = 1.month.ago..Time.current
    assert_includes GradeCard.for_date_range(range), @grade_card

    old_range = 2.months.ago..1.month.ago
    assert_not_includes GradeCard.for_date_range(old_range), @grade_card
  end

  # Delegate methods
  test "delegates url to medium" do
    @grade_card.save!
    assert_equal @medium.url, @grade_card.url
  end

  test "delegates thumbnail_url to medium" do
    @grade_card.save!
    assert_equal @medium.thumbnail_url, @grade_card.thumbnail_url
  end

  # Mentee association
  test "mentee has_many grade_cards" do
    @grade_card.save!
    assert_includes @mentee.grade_cards, @grade_card
  end

  test "destroying mentee destroys grade_cards" do
    @grade_card.save!
    CloudflareImagesService.stubs(:delete).returns(true)
    assert_difference "GradeCard.count", -1 do
      @mentee_user.destroy
    end
  end

  # Cascade delete medium
  test "destroying grade_card destroys associated medium" do
    @grade_card.save!

    CloudflareImagesService.stubs(:delete).returns(true)
    assert_difference "Medium.count", -1 do
      @grade_card.destroy
    end
  end

  test "destroying grade_card does not destroy general category medium" do
    general_medium = Medium.create!(
      uploaded_by: @admin,
      cloudflare_id: "gc_general_#{SecureRandom.hex(8)}",
      filename: "general.jpg",
      media_type: "image",
      category: "general"
    )
    grade_card = GradeCard.create!(mentee: @mentee, medium: general_medium)

    assert_no_difference "Medium.count" do
      grade_card.destroy
    end
  end

  # Access helpers
  test "mentee_user returns the mentee's user" do
    @grade_card.save!
    assert_equal @mentee_user, @grade_card.mentee_user
  end
end
