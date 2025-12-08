class CreateMessageRecipients < ActiveRecord::Migration[8.1]
  def change
    create_table :message_recipients do |t|
      t.references :message, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.boolean :is_read, null: false, default: false

      t.timestamps
    end

    add_index :message_recipients, [:message_id, :recipient_id], unique: true
    add_index :message_recipients, [:recipient_id, :is_read]
  end
end
