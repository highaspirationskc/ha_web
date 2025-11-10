class CreateOlympicSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :olympic_seasons do |t|
      t.string :name, null: false
      t.integer :start_month, null: false
      t.integer :start_day, null: false
      t.integer :end_month, null: false
      t.integer :end_day, null: false

      t.timestamps
    end
  end
end
