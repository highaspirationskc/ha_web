class AddFieldsToSeasEvaluations < ActiveRecord::Migration[8.1]
  def change
    add_column :seas_evaluations, :evaluation_year, :integer
    add_column :seas_evaluations, :sent_at, :datetime
    add_column :seas_evaluations, :review_started_at, :datetime
    add_column :seas_evaluations, :email_sent_at, :datetime
    add_column :seas_evaluations, :in_app_sent_at, :datetime
    add_index :seas_evaluations, [:mentee_id, :evaluation_year], unique: true,
              name: "index_seas_evaluations_on_mentee_and_year"
  end
end
