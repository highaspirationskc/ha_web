class CreateRoleModelsAndUpdateSchema < ActiveRecord::Migration[8.1]
  def change
    # Create mentors table
    create_table :mentors do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    # Create mentees table
    create_table :mentees do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :mentor, null: true, foreign_key: true
      t.references :team, null: true, foreign_key: true
      t.timestamps
    end

    # Create guardians table
    create_table :guardians do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    # Create staff table
    create_table :staff do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :permission_level, null: false, default: "standard"
      t.timestamps
    end

    # Create volunteers table
    create_table :volunteers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    # Update family_members table - change from user-to-user to guardian-to-mentee
    # First remove old foreign keys and columns
    remove_foreign_key :family_members, column: :user_id
    remove_foreign_key :family_members, column: :related_user_id
    remove_index :family_members, column: [:user_id, :related_user_id]
    remove_index :family_members, column: :user_id
    remove_index :family_members, column: :related_user_id
    remove_column :family_members, :user_id, :integer
    remove_column :family_members, :related_user_id, :integer

    # Add new columns for guardian and mentee
    add_reference :family_members, :guardian, null: false, foreign_key: true
    add_reference :family_members, :mentee, null: false, foreign_key: true
    add_index :family_members, [:guardian_id, :mentee_id], unique: true

    # Change relationship_type from integer to string
    remove_column :family_members, :relationship_type, :integer
    add_column :family_members, :relationship_type, :string, null: false

    # Update teams.color from integer to string
    remove_column :teams, :color, :integer
    add_column :teams, :color, :string, null: false

    # Update event_logs.log_type from integer to string
    remove_column :event_logs, :log_type, :integer
    add_column :event_logs, :log_type, :string, null: false, default: "registered"

    # Update event_types.category from integer to string
    remove_column :event_types, :category, :integer
    add_column :event_types, :category, :string, null: false

    # Remove role and team_id from users table
    remove_index :users, :role
    remove_index :users, :team_id
    remove_foreign_key :users, :teams
    remove_column :users, :role, :integer
    remove_column :users, :team_id, :integer
  end
end
