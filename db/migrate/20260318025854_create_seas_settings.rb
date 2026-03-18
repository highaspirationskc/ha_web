class CreateSeasSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :seas_settings do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
    add_index :seas_settings, :key, unique: true
  end
end
