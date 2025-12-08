class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :parent, null: true, foreign_key: { to_table: :messages }
      t.string :subject, null: false
      t.text :message, null: false
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :messages, :created_at
  end
end
