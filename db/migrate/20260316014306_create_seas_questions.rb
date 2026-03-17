class CreateSeasQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :seas_questions do |t|
      t.references :seas_section, null: false, foreign_key: true
      t.string :text, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :seas_questions, [:seas_section_id, :position], unique: true
  end
end
