class AddReplyModeToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :reply_mode, :integer, default: 0, null: false
  end
end
