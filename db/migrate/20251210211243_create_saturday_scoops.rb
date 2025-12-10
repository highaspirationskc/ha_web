class CreateSaturdayScoops < ActiveRecord::Migration[8.1]
  def change
    create_table :saturday_scoops do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.text :description
      t.references :image, foreign_key: { to_table: :media }
      t.references :video, foreign_key: { to_table: :media }
      t.date :publish_on
      t.boolean :published, default: false, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.timestamps
    end

    add_index :saturday_scoops, [:published, :publish_on]
  end
end
