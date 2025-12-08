class Staff < ApplicationRecord
  self.table_name = "staff"

  belongs_to :user

  enum :permission_level, { standard: "standard", admin: "admin" }, default: :standard
end
