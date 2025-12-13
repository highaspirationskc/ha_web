require "test_helper"

class MediumTest < ActiveSupport::TestCase
  def setup
    @user = create_user
    @medium = Medium.new(
      uploaded_by: @user,
      cloudflare_id: "test_cloudflare_id_#{SecureRandom.hex(8)}",
      filename: "test_image.jpg",
      media_type: "image",
      content_type: "image/jpeg"
    )
  end

  test "valid medium" do
    assert @medium.valid?
  end

  test "requires uploaded_by" do
    @medium.uploaded_by = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:uploaded_by], "must exist"
  end

  test "requires cloudflare_id" do
    @medium.cloudflare_id = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:cloudflare_id], "can't be blank"
  end

  test "requires unique cloudflare_id" do
    @medium.save!
    duplicate = @medium.dup
    duplicate.cloudflare_id = @medium.cloudflare_id
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:cloudflare_id], "has already been taken"
  end

  test "requires filename" do
    @medium.filename = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:filename], "can't be blank"
  end

  test "requires media_type" do
    @medium.media_type = nil
    assert_not @medium.valid?
    assert_includes @medium.errors[:media_type], "can't be blank"
  end

  test "media_type must be image or video" do
    @medium.media_type = "audio"
    assert_not @medium.valid?
    assert_includes @medium.errors[:media_type], "is not included in the list"

    @medium.media_type = "image"
    assert @medium.valid?

    @medium.media_type = "video"
    assert @medium.valid?
  end

  test "url generates cloudflare delivery url" do
    @medium.save!
    url = @medium.url
    assert_includes url, "imagedelivery.net"
    assert_includes url, @medium.cloudflare_id
    assert_includes url, "public"
  end

  test "url accepts variant parameter" do
    @medium.save!
    url = @medium.url(variant: "thumbnail")
    assert_includes url, "thumbnail"
  end

  test "thumbnail_url returns thumbnail variant" do
    @medium.save!
    url = @medium.thumbnail_url
    assert_includes url, "thumbnail"
  end

  test "image? returns true for images" do
    @medium.media_type = "image"
    assert @medium.image?
  end

  test "image? returns false for videos" do
    @medium.media_type = "video"
    assert_not @medium.image?
  end

  test "video? returns true for videos" do
    @medium.media_type = "video"
    assert @medium.video?
  end

  test "video? returns false for images" do
    @medium.media_type = "image"
    assert_not @medium.video?
  end

  test "in_use? returns false when not used" do
    @medium.save!
    assert_not @medium.in_use?
  end

  test "in_use? returns true when used by event" do
    @medium.save!
    event_type = EventType.create!(name: "Test Type", category: "org", point_value: 10)
    Event.create!(
      name: "Test Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @user,
      image: @medium
    )
    assert @medium.in_use?
  end

  test "usage returns empty array when not used" do
    @medium.save!
    assert_empty @medium.usage
  end

  test "usage returns list of usages" do
    @medium.save!
    event_type = EventType.create!(name: "Test Type2", category: "org", point_value: 10)
    event = Event.create!(
      name: "Test Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @user,
      image: @medium
    )

    usages = @medium.usage
    assert_equal 1, usages.length
    assert_equal "Event", usages.first[:type]
    assert_equal event, usages.first[:record]
  end

  test "usage_count returns correct count" do
    @medium.save!
    assert_equal 0, @medium.usage_count

    event_type = EventType.create!(name: "Test Type3", category: "org", point_value: 10)
    Event.create!(
      name: "Test Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @user,
      image: @medium
    )

    assert_equal 1, @medium.usage_count
  end

  test "images scope returns only images" do
    @medium.save!
    video = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "video_id_#{SecureRandom.hex(8)}",
      filename: "test_video.mp4",
      media_type: "video"
    )

    images = Medium.images
    assert_includes images, @medium
    assert_not_includes images, video
  end

  test "videos scope returns only videos" do
    @medium.save!
    video = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "video_id_#{SecureRandom.hex(8)}",
      filename: "test_video.mp4",
      media_type: "video"
    )

    videos = Medium.videos
    assert_not_includes videos, @medium
    assert_includes videos, video
  end

  # Category tests

  test "category defaults to general" do
    @medium.save!
    assert_equal "general", @medium.category
  end

  test "category must be valid" do
    @medium.category = "invalid"
    assert_not @medium.valid?
    assert_includes @medium.errors[:category], "is not included in the list"
  end

  test "category can be general, avatar, icon, or grade_card" do
    %w[general avatar icon grade_card].each do |cat|
      @medium.category = cat
      assert @medium.valid?, "Expected #{cat} to be valid"
    end
  end

  test "general scope returns only general media" do
    @medium.save!
    avatar = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "avatar_id_#{SecureRandom.hex(8)}",
      filename: "avatar.jpg",
      media_type: "image",
      category: "avatar"
    )

    general = Medium.general
    assert_includes general, @medium
    assert_not_includes general, avatar
  end

  test "avatars scope returns only avatar media" do
    @medium.save!
    avatar = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "avatar_id_#{SecureRandom.hex(8)}",
      filename: "avatar.jpg",
      media_type: "image",
      category: "avatar"
    )

    avatars = Medium.avatars
    assert_not_includes avatars, @medium
    assert_includes avatars, avatar
  end

  test "icons scope returns only icon media" do
    @medium.save!
    icon = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "icon_id_#{SecureRandom.hex(8)}",
      filename: "icon.png",
      media_type: "image",
      category: "icon"
    )

    icons = Medium.icons
    assert_not_includes icons, @medium
    assert_includes icons, icon
  end

  test "thumbnail_url returns thumbnail variant for general" do
    @medium.category = "general"
    @medium.save!
    assert_includes @medium.thumbnail_url, "thumbnail"
  end

  test "thumbnail_url returns avatar variant for avatars" do
    @medium.category = "avatar"
    @medium.save!
    assert_includes @medium.thumbnail_url, "avatar"
  end

  test "thumbnail_url returns icon variant for icons" do
    @medium.category = "icon"
    @medium.save!
    assert_includes @medium.thumbnail_url, "icon"
  end

  test "grade_cards scope returns only grade_card media" do
    @medium.save!
    grade_card_medium = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "grade_card_id_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )

    grade_cards = Medium.grade_cards
    assert_not_includes grade_cards, @medium
    assert_includes grade_cards, grade_card_medium
  end

  test "library scope returns only general media" do
    @medium.save!
    avatar = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "avatar_lib_#{SecureRandom.hex(8)}",
      filename: "avatar.jpg",
      media_type: "image",
      category: "avatar"
    )
    icon = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "icon_lib_#{SecureRandom.hex(8)}",
      filename: "icon.png",
      media_type: "image",
      category: "icon"
    )
    grade_card_medium = Medium.create!(
      uploaded_by: @user,
      cloudflare_id: "gc_lib_#{SecureRandom.hex(8)}",
      filename: "grade_card.jpg",
      media_type: "image",
      category: "grade_card"
    )

    library = Medium.library
    assert_includes library, @medium
    assert_not_includes library, avatar
    assert_not_includes library, icon
    assert_not_includes library, grade_card_medium
  end

  test "single_use? returns false for general category" do
    @medium.category = "general"
    assert_not @medium.single_use?
  end

  test "single_use? returns true for avatar category" do
    @medium.category = "avatar"
    assert @medium.single_use?
  end

  test "single_use? returns true for icon category" do
    @medium.category = "icon"
    assert @medium.single_use?
  end

  test "single_use? returns true for grade_card category" do
    @medium.category = "grade_card"
    assert @medium.single_use?
  end

  test "thumbnail_url returns thumbnail variant for grade_card" do
    @medium.category = "grade_card"
    @medium.save!
    assert_includes @medium.thumbnail_url, "thumbnail"
  end
end
