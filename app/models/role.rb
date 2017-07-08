class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  CANDIDATE = "candidate"
  ADMIN = "admin"
  def self.admin
    Role.find_by_name(ADMIN)
  end

  def self.candidate
    Role.find_by_name(CANDIDATE)
  end
end
