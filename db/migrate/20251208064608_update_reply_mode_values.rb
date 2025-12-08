class UpdateReplyModeValues < ActiveRecord::Migration[8.1]
  def up
    # Shift existing values: old 1 (reply_to_all) -> new 2, old 0 (reply_to_sender) -> new 1
    # Do reply_to_all first to avoid conflicts
    execute "UPDATE messages SET reply_mode = 2 WHERE reply_mode = 1"
    execute "UPDATE messages SET reply_mode = 1 WHERE reply_mode = 0"

    # Update default to reply_to_sender (1)
    change_column_default :messages, :reply_mode, 1
  end

  def down
    # Reverse: new 1 (reply_to_sender) -> old 0, new 2 (reply_to_all) -> old 1
    execute "UPDATE messages SET reply_mode = 0 WHERE reply_mode = 1"
    execute "UPDATE messages SET reply_mode = 1 WHERE reply_mode = 2"

    change_column_default :messages, :reply_mode, 0
  end
end
