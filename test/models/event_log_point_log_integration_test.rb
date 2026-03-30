require "test_helper"

class EventLogPointLogIntegrationTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin_event_log@example.com")
    @mentee_user = create_mentee_user(email: "mentee_event_log@example.com")
    @mentee = @mentee_user.mentee

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    @event_type = EventType.create!(name: "Test Event", category: "org", point_value: 50)
    @event = Event.create!(name: "Test Event", event_date: Time.current, event_type: @event_type, created_by: @admin)
  end

  test "event log with arrived status creates point log" do
    assert_difference "PointLog.count", 1 do
      EventLog.create!(
        user: @mentee_user,
        event: @event,
        points_awarded: 50,
        log_type: "arrived"
      )
    end

    @mentee.reload
    assert_equal 50, @mentee.total_points
  end

  test "event log without arrived status does not create point log" do
    assert_no_difference "PointLog.count" do
      EventLog.create!(
        user: @mentee_user,
        event: @event,
        points_awarded: 50
        # log_type defaults to "registered"
      )
    end

    @mentee.reload
    assert_equal 0, @mentee.total_points
  end
end
