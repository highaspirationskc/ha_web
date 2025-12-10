require "test_helper"

class SaturdayScoopTest < ActiveSupport::TestCase
  def setup
    @user = create_user(email: "scoop_creator@example.com")
    @image = create_medium(@user, media_type: "image")
    @video = create_medium(@user, media_type: "video")
  end

  test "valid saturday scoop" do
    scoop = SaturdayScoop.new(
      title: "Test Scoop",
      author: "John Doe",
      description: "This is a test scoop.",
      created_by: @user
    )
    assert scoop.valid?
  end

  test "requires title" do
    scoop = SaturdayScoop.new(author: "John Doe", created_by: @user)
    assert_not scoop.valid?
    assert_includes scoop.errors[:title], "can't be blank"
  end

  test "requires author" do
    scoop = SaturdayScoop.new(title: "Test Scoop", created_by: @user)
    assert_not scoop.valid?
    assert_includes scoop.errors[:author], "can't be blank"
  end

  test "requires created_by" do
    scoop = SaturdayScoop.new(title: "Test Scoop", author: "John Doe")
    assert_not scoop.valid?
    assert_includes scoop.errors[:created_by], "must exist"
  end

  test "can have image" do
    scoop = SaturdayScoop.create!(
      title: "Test Scoop",
      author: "John Doe",
      created_by: @user,
      image: @image
    )
    assert_equal @image, scoop.image
  end

  test "can have video" do
    scoop = SaturdayScoop.create!(
      title: "Test Scoop",
      author: "John Doe",
      created_by: @user,
      video: @video
    )
    assert_equal @video, scoop.video
  end

  test "image must be image type" do
    scoop = SaturdayScoop.new(
      title: "Test Scoop",
      author: "John Doe",
      created_by: @user,
      image: @video
    )
    assert_not scoop.valid?
    assert_includes scoop.errors[:image], "must be an image type"
  end

  test "video must be video type" do
    scoop = SaturdayScoop.new(
      title: "Test Scoop",
      author: "John Doe",
      created_by: @user,
      video: @image
    )
    assert_not scoop.valid?
    assert_includes scoop.errors[:video], "must be a video type"
  end

  test "published scope returns only published scoops with past or nil publish_on" do
    published_past = SaturdayScoop.create!(
      title: "Published Past",
      author: "Author",
      created_by: @user,
      published: true,
      publish_on: Date.yesterday
    )
    published_nil = SaturdayScoop.create!(
      title: "Published Nil Date",
      author: "Author",
      created_by: @user,
      published: true,
      publish_on: nil
    )
    published_future = SaturdayScoop.create!(
      title: "Published Future",
      author: "Author",
      created_by: @user,
      published: true,
      publish_on: Date.tomorrow
    )
    unpublished = SaturdayScoop.create!(
      title: "Unpublished",
      author: "Author",
      created_by: @user,
      published: false
    )

    published = SaturdayScoop.published

    assert_includes published, published_past
    assert_includes published, published_nil
    assert_not_includes published, published_future
    assert_not_includes published, unpublished
  end

  test "unpublished scope returns drafts and future scoops" do
    published_past = SaturdayScoop.create!(
      title: "Published Past",
      author: "Author",
      created_by: @user,
      published: true,
      publish_on: Date.yesterday
    )
    published_future = SaturdayScoop.create!(
      title: "Published Future",
      author: "Author",
      created_by: @user,
      published: true,
      publish_on: Date.tomorrow
    )
    unpublished = SaturdayScoop.create!(
      title: "Unpublished",
      author: "Author",
      created_by: @user,
      published: false
    )

    result = SaturdayScoop.unpublished

    assert_not_includes result, published_past
    assert_includes result, published_future
    assert_includes result, unpublished
  end

  test "recent scope orders by publish_on desc then created_at desc" do
    old_scoop = SaturdayScoop.create!(
      title: "Old Scoop",
      author: "Author",
      created_by: @user,
      publish_on: 1.week.ago
    )
    new_scoop = SaturdayScoop.create!(
      title: "New Scoop",
      author: "Author",
      created_by: @user,
      publish_on: Date.current
    )

    result = SaturdayScoop.recent

    assert_equal new_scoop, result.first
    assert_equal old_scoop, result.second
  end

  test "published_and_live? returns true when published and publish_on is past or nil" do
    scoop = SaturdayScoop.new(published: true, publish_on: Date.yesterday)
    assert scoop.published_and_live?

    scoop.publish_on = nil
    assert scoop.published_and_live?
  end

  test "published_and_live? returns false when not published" do
    scoop = SaturdayScoop.new(published: false, publish_on: Date.yesterday)
    assert_not scoop.published_and_live?
  end

  test "published_and_live? returns false when publish_on is future" do
    scoop = SaturdayScoop.new(published: true, publish_on: Date.tomorrow)
    assert_not scoop.published_and_live?
  end

  private

  def create_medium(user, media_type: "image")
    Medium.create!(
      uploaded_by: user,
      cloudflare_id: "cf_#{SecureRandom.hex(8)}",
      filename: "test.#{media_type == 'image' ? 'jpg' : 'mp4'}",
      media_type: media_type,
      content_type: media_type == "image" ? "image/jpeg" : "video/mp4"
    )
  end
end
