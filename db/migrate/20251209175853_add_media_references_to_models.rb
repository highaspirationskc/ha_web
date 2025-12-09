class AddMediaReferencesToModels < ActiveRecord::Migration[8.1]
  def change
    # Add media reference to events
    add_reference :events, :image, foreign_key: { to_table: :media }
    remove_column :events, :image_url, :string

    # Add media reference to teams
    add_reference :teams, :icon, foreign_key: { to_table: :media }
    remove_column :teams, :icon_url, :string

    # Add media reference to users
    add_reference :users, :avatar, foreign_key: { to_table: :media }
    remove_column :users, :avatar_url, :string
  end
end
