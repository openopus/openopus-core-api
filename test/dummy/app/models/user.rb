class User < ApplicationRecord
  enum role: [:admin, :user]

  has_many :employments
  has_many :organizations, through: :employments

  has_many :station_roles
  has_many :stations, through: :station_roles
end
