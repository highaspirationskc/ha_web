class MigrateEventRegistrationsToEventLogs < ActiveRecord::Migration[8.1]
  def up
    # Migrate all event_registrations to event_logs with log_type: registered
    execute <<-SQL
      INSERT INTO event_logs (event_id, user_id, log_type, logged_at, points_awarded, created_at, updated_at)
      SELECT
        event_id,
        user_id,
        0 as log_type,  -- 0 = registered
        registration_date as logged_at,
        0 as points_awarded,
        created_at,
        updated_at
      FROM event_registrations
      WHERE NOT EXISTS (
        SELECT 1 FROM event_logs
        WHERE event_logs.event_id = event_registrations.event_id
        AND event_logs.user_id = event_registrations.user_id
        AND event_logs.log_type = 0
      )
    SQL
  end

  def down
    # Reverse migration: restore event_registrations from event_logs
    execute <<-SQL
      INSERT INTO event_registrations (event_id, user_id, registration_date, created_at, updated_at)
      SELECT
        event_id,
        user_id,
        logged_at as registration_date,
        created_at,
        updated_at
      FROM event_logs
      WHERE log_type = 0  -- registered
      AND NOT EXISTS (
        SELECT 1 FROM event_registrations
        WHERE event_registrations.event_id = event_logs.event_id
        AND event_registrations.user_id = event_logs.user_id
      )
    SQL
  end
end
