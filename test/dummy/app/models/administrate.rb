class Administrate < ApplicationRecord
  belongs_to :administrator, class_name: :User
  belongs_to :recipient, class_name: :User
end
