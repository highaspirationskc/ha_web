class CreateUserDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :user_devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :fcm_token, null: false
      t.string :device_name
      t.string :platform, null: false

      t.timestamps
    end
    add_index :user_devices, :fcm_token, unique: true
  end
end
