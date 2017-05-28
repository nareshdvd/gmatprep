class Plan < ActiveRecord::Base
  has_many :subscriptions
  FREE_PLAN='Free Plan'
end
