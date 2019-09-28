class Organization < ApplicationRecord
  has_many :regions
  has_many :stations, through: :regions
  has_many :employments
  has_many :users, through: :employments
end
