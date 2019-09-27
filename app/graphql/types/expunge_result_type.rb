module Types
  class ExpungeResultType < Types::BaseObject
    field :success, Boolean, null: false
    field :errors, [UserErrorType], null: false
  end
end
