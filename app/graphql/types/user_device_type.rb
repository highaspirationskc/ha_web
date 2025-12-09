module Types
  class UserDeviceType < Types::BaseObject
    field :id, ID, null: false
    field :device_name, String, null: true
    field :platform, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
