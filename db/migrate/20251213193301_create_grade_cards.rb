class CreateGradeCards < ActiveRecord::Migration[8.1]
  def change
    create_table :grade_cards do |t|
      t.references :mentee, null: false, foreign_key: true
      t.references :medium, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
