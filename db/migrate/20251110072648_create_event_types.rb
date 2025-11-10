class CreateEventTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_types do |t|
      t.string :name, null: false
      t.integer :point_value, null: false
      t.integer :category, null: false

      t.timestamps
    end

    add_index :event_types, :name, unique: true
  end
end
