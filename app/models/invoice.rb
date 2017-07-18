class Invoice < ActiveRecord::Base
  belongs_to :subscription
  has_many :payments
  has_one :successful_payment, ->{where("payments.status=?", Payment::STATUS[:success])}, class_name: "Payment", foreign_key: "invoice_id"
  STATUS = {
    pending: 0,
    paid: 1
  }
  #after_create :create_pending_payment

  def create_pending_payment(params)
    payment_method = payment.get_or_add_payment_method(params[:payment_method], params.except(:payment_method))
    payment = self.payments.create(
      status: Payment::STATUS[:pending],
      amount: self.subscription.plan.amount,
      currency: self.subscription.plan.currency
    )
    
    return payment, payment_method
  end

  def paid?
    self.status == STATUS[:paid]
  end

  def pending?
    self.status == STATUS[:pending]
  end
end
