class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :user
  has_many :papers, dependent: :destroy
  has_many :payments, dependent: :destroy
  after_create :create_payment
  scope :with_plan, -> { joins(:plan) }
  scope :with_payments, -> { joins(:payments).preload(:payments) }
  scope :not_free, -> { joins(:plan).where("(plans.name != ?)", Plan::FREE_PLAN) }
  scope :payment_pending, -> { joins(:payments).where("payments.status = ?", Payment::STATUS[:pending]) }
  scope :payment_initiated, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:initiated]) }
  scope :payment_success, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:initiated]) }
  scope :payment_paid, -> { joins(:payments).where("payments.status = ? ", Payment::STATUS[:paid]) }
  scope :payment_paid_or_success, -> { joins(:payments).where("payments.status IN (?)", [Payment::STATUS[:paid], Payment::STATUS[:success]]) }

  def create_payment
    return true if self.plan.free_plan?
    self.payments.create(status: Payment::STATUS[:pending], amount: self.plan.amount, currency: self.plan.currency, gm_txn_id: SecureRandom.hex(8))
  end

  def elapsed?
    return false if self.plan.interval_count == 0
    self.start_date + self.plan.interval_count.send(self.plan.interval.pluralize.downcase) < Date.today
  end

  def not_elapsed?
    !elapsed?
  end

  def exhausted?
    return true if self.papers.count == self.plan.paper_count && self.papers.last.finished?
    return false
  end

  def not_exhausted?
    !exhausted?
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
