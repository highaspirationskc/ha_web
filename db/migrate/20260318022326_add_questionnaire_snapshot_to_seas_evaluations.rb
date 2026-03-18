class AddQuestionnaireSnapshotToSeasEvaluations < ActiveRecord::Migration[8.1]
  def change
    add_column :seas_evaluations, :questionnaire_snapshot, :text
  end
end
