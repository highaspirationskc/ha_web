class AddDescriptionToSeasDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :seas_domains, :description, :string
  end
end
