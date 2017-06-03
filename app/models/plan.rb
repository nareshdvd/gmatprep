class Plan < ActiveRecord::Base
  has_many :subscriptions
  FREE_PLAN='Free Plan'

  def free_plan?
    return self.name == FREE_PLAN
  end

  def self.free_plan
    return self.find_by_name(FREE_PLAN)
  end
end
