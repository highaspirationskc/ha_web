class AddSupportToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :support, :boolean, default: false, null: false
  end
end
