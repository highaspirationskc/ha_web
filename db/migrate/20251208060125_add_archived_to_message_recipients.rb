class AddArchivedToMessageRecipients < ActiveRecord::Migration[8.1]
  def change
    add_column :message_recipients, :archived, :boolean, default: false, null: false
  end
end
