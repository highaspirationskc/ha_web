class CreatePointLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :point_logs do |t|
      t.references :mentee, null: false, foreign_key: true
      t.integer :points, null: false
      t.string :log_type, null: false, default: "adjustment"
      t.string :reason, null: false
      t.references :source, polymorphic: true
      t.references :awarded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :point_logs, [:mentee_id, :created_at], order: { created_at: :desc }
    add_index :point_logs, :log_type
  end
end
