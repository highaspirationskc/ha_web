class AddEnrollmentDateToMentees < ActiveRecord::Migration[8.1]
  def change
    add_column :mentees, :enrollment_date, :date
  end
end
