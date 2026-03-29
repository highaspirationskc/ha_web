class CreateRedemptions < ActiveRecord::Migration[8.1]
  def change
    create_table :redemptions do |t|
      t.references :mentee, null: false, foreign_key: true
      t.references :incentive, null: false, foreign_key: true
      t.integer :points_spent, null: false
      t.string :status, null: false, default: "pending"
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      t.datetime :approved_at
      t.text :notes
      t.timestamps
    end

    add_index :redemptions, :status
    add_index :redemptions, [:mentee_id, :status]
  end
end
