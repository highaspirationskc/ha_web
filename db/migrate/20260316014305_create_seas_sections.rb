class CreateSeasSections < ActiveRecord::Migration[8.1]
  def change
    create_table :seas_sections do |t|
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :seas_sections, :position, unique: true
  end
end
