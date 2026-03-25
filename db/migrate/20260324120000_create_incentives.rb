class CreateIncentives < ActiveRecord::Migration[8.1]
  def change
    create_table :incentives do |t|
      t.string :name, null: false
      t.text :description
      t.integer :point_cost, null: false
      t.string :incentive_type, null: false, default: "individual" # individual or team
      t.boolean :active, null: false, default: true
      t.references :image, foreign_key: { to_table: :media }, null: true
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.timestamps
    end

    add_index :incentives, :active
    add_index :incentives, :incentive_type
  end
end
