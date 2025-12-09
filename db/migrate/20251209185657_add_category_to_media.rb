class AddCategoryToMedia < ActiveRecord::Migration[8.1]
  def change
    add_column :media, :category, :string, default: "general", null: false
    add_index :media, :category
  end
end
