class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :user
  has_many :papers
  before_create :activate_subscription
  after_create :deactivate_users_other_subscriptions
  def activate_subscription
    self.is_active = true
  end

  def deactivate_users_other_subscriptions
    self.user.subscriptions.where("id != ? AND is_active = ?", self.id, true).update_all(is_active: false)
  end

  def in_progress_paper
    return self.papers.where("start_time IS NULL OR (finish_time IS NULL AND DATE_ADD(start_time, INTERVAL #{Paper::MINUTES} MINUTE) > NOW())").last
  end

  def remaining_paper_count
    return self.plan.paper_count - self.papers.count
  end
end
