class DropEventRegistrations < ActiveRecord::Migration[8.1]
  def up
    drop_table :event_registrations
  end

  def down
    create_table :event_registrations do |t|
      t.integer :event_id, null: false
      t.integer :user_id, null: false
      t.datetime :registration_date, null: false
      t.timestamps
    end

    add_index :event_registrations, :event_id
    add_index :event_registrations, :user_id
    add_index :event_registrations, [:event_id, :user_id], unique: true
    add_index :event_registrations, :registration_date
  end
end
