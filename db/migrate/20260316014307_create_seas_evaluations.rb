class CreateSeasEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :seas_evaluations do |t|
      t.references :mentee, null: false, foreign_key: true
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.integer :current_section_position
      t.datetime :completed_at
      t.integer :reviewer_id
      t.datetime :reviewed_at
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :seas_evaluations, :token, unique: true
    add_foreign_key :seas_evaluations, :users, column: :reviewer_id
  end
end
