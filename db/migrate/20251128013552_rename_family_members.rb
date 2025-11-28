class RenameFamilyMembers < ActiveRecord::Migration[8.1]
  def change
    rename_table :user_relationships, :family_members
  end
end
