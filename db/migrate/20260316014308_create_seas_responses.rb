class CreateSeasResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :seas_responses do |t|
      t.references :seas_evaluation, null: false, foreign_key: true
      t.references :seas_question, null: false, foreign_key: true
      t.integer :score, null: false
      t.string :review_action
      t.integer :adjusted_score
      t.text :feedback

      t.timestamps
    end

    add_index :seas_responses, [:seas_evaluation_id, :seas_question_id], unique: true, name: "index_seas_responses_on_evaluation_and_question"
  end
end
