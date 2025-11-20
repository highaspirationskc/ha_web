class RefactorEventLogs < ActiveRecord::Migration[8.1]
  def change
    # Add new columns
    add_column :event_logs, :log_type, :integer, null: false, default: 0
    add_column :event_logs, :logged_at, :datetime

    # Set logged_at to participated_at for existing records
    reversible do |dir|
      dir.up do
        execute "UPDATE event_logs SET logged_at = participated_at WHERE logged_at IS NULL"
      end
    end

    # Make logged_at not null after backfilling
    change_column_null :event_logs, :logged_at, false

    # Remove old column
    remove_column :event_logs, :participated_at, :datetime

    # Add index for log_type queries
    add_index :event_logs, :log_type
    add_index :event_logs, [:event_id, :log_type]
  end
end
