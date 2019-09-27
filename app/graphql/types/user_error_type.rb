module Types
  class UserErrorType < Types::BaseObject
    field :message, String, null: false
    field :path, [String], null: true,
          description: "Which input value this error came from"
  end
end
