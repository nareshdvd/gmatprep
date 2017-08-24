class Invoice < ActiveRecord::Base
  belongs_to :subscription
  has_many :payments, dependent: :destroy
  has_one :successful_payment, ->{where("payments.status=?", Payment::STATUS[:success])}, class_name: "Payment", foreign_key: "invoice_id"
  STATUS = {
    pending: 0,
    paid: 1
  }
  #after_create :create_pending_payment

  def create_pending_payment(params)
    if params[:payment_method] == "PayuPaymentMethod"
      amt = Concurrency.convert(self.subscription.plan.amount, self.subscription.plan.currency, "INR").round(2)
      curr = "INR"
    else
      amt = self.subscription.plan.amount
      curr = self.subscription.plan.currency
    end
    payment = self.payments.create(
      status: Payment::STATUS[:pending],
      amount: amt,
      currency: curr
    )
    payment_method = payment.get_or_add_payment_method(params[:payment_method], params.except(:payment_method))
    return payment, payment_method
  end

  def paid?
    self.status == STATUS[:paid]
  end

  def pending?
    self.status == STATUS[:pending]
  end

  def mark_paid
    self.update_attribute(:status, STATUS[:paid])
  end
end
