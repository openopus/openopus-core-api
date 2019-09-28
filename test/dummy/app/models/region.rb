class Region < ApplicationRecord
  belongs_to :organization
  has_many :stations
end
