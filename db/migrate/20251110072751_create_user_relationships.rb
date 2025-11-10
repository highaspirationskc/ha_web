class CreateUserRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :user_relationships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :related_user, null: false, foreign_key: { to_table: :users }
      t.integer :relationship_type, null: false

      t.timestamps
    end

    add_index :user_relationships, [:user_id, :related_user_id], unique: true
  end
end
