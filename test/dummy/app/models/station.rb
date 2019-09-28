class Station < ApplicationRecord
  belongs_to :region
  has_many :station_roles
  has_many :users, through: :station_roles
end
