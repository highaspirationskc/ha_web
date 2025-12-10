class CreateCommunityServiceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :community_service_records do |t|
      t.references :mentee, null: false, foreign_key: true
      t.string :event, null: false
      t.text :description
      t.date :event_date, null: false
      t.decimal :hours, precision: 5, scale: 2, null: false
      t.boolean :approved, null: false, default: true

      t.timestamps
    end
  end
end
