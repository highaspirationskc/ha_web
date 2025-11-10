class CreateEventLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :event_logs do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :participated_at, null: false
      t.integer :points_awarded, null: false

      t.timestamps
    end
  end
end
