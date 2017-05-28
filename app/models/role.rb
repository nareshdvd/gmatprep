class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  CANDIDATE = "candidate"
  ADMIN = "admin"
end
