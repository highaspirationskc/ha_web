class BackfillPointLogs < ActiveRecord::Migration[8.1]
  def up
    # Backfill attendance points from event_logs
    # Only for mentees who arrived at events (log_type = 'arrived')
    EventLog.where(log_type: "arrived").where("points_awarded > 0").find_each do |event_log|
      mentee = event_log.user.mentee
      next unless mentee.present?

      PointLog.create!(
        mentee: mentee,
        points: event_log.points_awarded,
        reason: "Attended #{event_log.event.name} on #{event_log.event.event_date.strftime("%B %d, %Y")}",
        awarded_by: nil, # Historical data - no specific user awarded these
        log_type: "attendance",
        source: event_log,
        created_at: event_log.created_at
      )
    end

    # Backfill redemption deductions from redemptions
    # For pending, approved, and deleted_no_refund statuses
    Redemption.where(status: ["pending", "approved", "deleted_no_refund"]).find_each do |redemption|
      PointLog.create!(
        mentee: redemption.mentee,
        points: -redemption.points_spent,
        reason: "Redeemed: #{redemption.incentive.name}",
        awarded_by: redemption.approved_by, # May be nil for pending redemptions
        log_type: "redemption",
        source: redemption,
        created_at: redemption.created_at
      )
    end

    # Backfill refunds for deleted redemptions
    Redemption.where(status: "deleted").find_each do |redemption|
      # First create the redemption deduction
      PointLog.create!(
        mentee: redemption.mentee,
        points: -redemption.points_spent,
        reason: "Redeemed: #{redemption.incentive.name}",
        awarded_by: redemption.approved_by, # May be nil for pending redemptions
        log_type: "redemption",
        source: redemption,
        created_at: redemption.created_at
      )

      # Then create the refund adjustment
      PointLog.create!(
        mentee: redemption.mentee,
        points: redemption.points_spent,
        reason: "Refund for deleted redemption: #{redemption.incentive.name}",
        awarded_by: nil, # Historical data - no specific user awarded these
        log_type: "adjustment",
        source: redemption,
        created_at: redemption.updated_at
      )
    end
  end

  def down
    # Remove all point logs with log_type 'attendance' that have event_logs as source
    # and all point logs with log_type 'redemption' or 'adjustment' that have redemptions as source
    execute <<-SQL.squish
      DELETE FROM point_logs
      WHERE source_type IN ('EventLog', 'Redemption')
    SQL
  end
end
