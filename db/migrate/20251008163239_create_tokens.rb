class CreateTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :tokens do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :token_hash, null: false
      t.string :device_name

      t.timestamps
    end

    add_index :tokens, :token_hash, unique: true
  end
end
