class RemoveAuthorForeignKeyFromMessages < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :author_id, true
  end
end
