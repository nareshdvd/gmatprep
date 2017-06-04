class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :user
  has_many :papers
  has_many :payments
  # before_create :activate_subscription
  # after_create :deactivate_users_other_subscriptions
  after_create :create_payment
  scope :with_plan, -> { joins(:plan) }
  scope :with_payments, -> { joins(:payments).preload(:payments) }
  scope :not_free, -> { joins(:plan).where("(plans.name != ?)", Plan::FREE_PLAN) }
  scope :payment_pending, -> { joins(:payments).where("payments.status = ?", Payment::STATUS[:pending]) }
  scope :payment_initiated, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:initiated]) }
  scope :payment_success, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:initiated]) }
  scope :payment_paid, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:paid]) }
  scope :payment_paid_or_success, -> { joins(:payments).where("payments.status IN (?)", [Payment::STATUS[:paid], Payment::STATUS[:success]]) }
  scope :not_elapsed, -> { where("
    (plans.interval = 0
        OR
        ((CASE
              WHEN plans.interval='MONTH' THEN DATE_ADD(subscriptions.created_at, INTERVAL plans.interval_count MONTH)
              WHEN plans.interval='WEEK' THEN DATE_ADD(subscriptions.created_at, INTERVAL plans.interval_count WEEK)
            END) > NOW()))") }

  scope :not_exhausted, -> {
    joins("LEFT OUTER JOIN papers ON papers.subscription_id=subscriptions.id").joins("LEFT OUTER JOIN papers_questions ON papers_questions.paper_id=papers.id").where("(papers.start_time IS NULL OR (DATE_ADD(papers.start_time, INTERVAL #{Paper::MINUTES} MINUTE) < NOW()))").select("subscriptions.*, papers_questions.paper_id, COUNT(papers_questions.id) as paper_question_count").group("papers.id").having("paper_question_count < #{Paper::QUESTION_COUNT}")
  }

  scope :with_payments, -> {
    joins(:payments)
  }

  def create_payment
    return true if self.plan.free_plan?
    self.payments.create(status: Payment::STATUS[:pending], amount: self.plan.amount, currency: self.plan.currency, gm_txn_id: SecureRandom.hex(8))
  end

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

  def paid?(payments_preloaded = false)
    if payments_preloaded == false
      return self.payments.where(status: Payment::STATUS[:paid]).present?
    else
      return self.payments.any?{|payment| payment.status == Payment::STATUS[:paid]}
    end
  end

  def success?(payments_preloaded = false)
    if payments_preloaded == false
      return self.payments.where(status: Payment::STATUS[:success]).present?
    else
      return self.payments.any?{|payment| payment.status == Payment::STATUS[:success]}
    end
  end

  def pending?(payments_preloaded = false)
    if payments_preloaded == false
      return self.payments.where(status: Payment::STATUS[:pending]).present?
    else
      return self.payments.any?{|payment| payment.status == Payment::STATUS[:pending]}
    end
  end

  def initiated?(payments_preloaded = false)
    if payments_preloaded == false
      return self.payments.where(status: Payment::STATUS[:initiated]).present?
    else
      return self.payments.any?{|payment| payment.status == Payment::STATUS[:initiated]}
    end
  end
end
