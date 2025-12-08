class CreateSupportUser < ActiveRecord::Migration[8.1]
  def up
    # Add system user flag first
    add_column :users, :is_system_user, :boolean, default: false, null: false

    # Create a system user for the Support inbox
    support_user = User.create!(
      email: "support@highaspirations.org",
      password: "Support#{SecureRandom.hex(16)}!",
      first_name: "Support",
      last_name: "Inbox",
      active: true
    )
    # Clear confirmation token since this is a system user
    support_user.update_columns(confirmation_token: nil, confirmation_sent_at: nil, is_system_user: true)
  end

  def down
    User.find_by(email: "support@highaspirations.org")&.destroy
    remove_column :users, :is_system_user
  end
end
