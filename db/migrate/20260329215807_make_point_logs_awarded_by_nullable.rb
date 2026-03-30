class MakePointLogsAwardedByNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :point_logs, :awarded_by_id, true
  end
end
