class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :cloudflare_id, null: false
      t.string :filename, null: false
      t.string :media_type, default: "image", null: false
      t.string :content_type
      t.integer :file_size
      t.integer :width
      t.integer :height
      t.string :alt_text
      t.timestamps
    end

    add_index :media, :cloudflare_id, unique: true
    add_index :media, :media_type
  end
end
