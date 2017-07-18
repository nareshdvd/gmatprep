class Subscription < ActiveRecord::Base
  belongs_to :plan
  belongs_to :user
  has_one :invoice
  has_many :papers, dependent: :destroy
  # after_create :add_invoice
  scope :with_plan, -> { joins(:plan) }
  scope :not_free, -> { where("(plans.name != ?)", Plan::FREE_PLAN) }
  scope :with_invoice, -> { joins(:invoice) }
  scope :purchased, -> {
    with_plan.not_free.with_invoice.where("invoices.status=?", Invoice::STATUS[:paid])
  }
  scope :unpaid, -> {
    with_plan.not_free.with_invoice.where("invoices.status=?", Invoice::STATUS[:pending])
  }
  def add_invoice(payment_params)
    return true if self.plan.free_plan?
    sub_invoice = self.create_invoice(status: Invoice::STATUS[:pending])
    payment, payment_method = sub_invoice.create_pending_payment(payment_params)
    return sub_invoice, payment, payment_method
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

  def paid?
    self.invoice.status == Invoice::STATUS[:paid]
  end
end
