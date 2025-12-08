class RemoveIsSystemUserFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :is_system_user, :boolean, default: false, null: false
  end
end
