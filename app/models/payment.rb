class Payment < ActiveRecord::Base
  include PayPal::SDK::REST
  include PayPal::SDK::Core::Logging
  STATUS={
    pending: 0,
    success: 1,
    paid: 2,
    canceled: 3,
    failed: 4
  }
  belongs_to :invoice
  has_many :payment_methods, dependent: :destroy
  has_one :success_payment_method, -> {where("payment_methods.status=?", PaymentMethod::STATUS[:success])}, class_name: "PaymentMethod", foreign_key: "payment_id"

  scope :pending, -> {where("status=?", STATUS[:pending])}

  serialize :txn_notify_data, JSON
  serialize :transaction_data, JSON



  def pending?
    self.status == STATUS[:pending]
  end

  def paid?
    self.status == STATUS[:paid]
  end

  def canceled?
    self.status == STATUS[:canceled]
  end

  def failed?
    self.status == STATUS[:failed]
  end

  def success?
    self.status == STATUS[:success]
  end

  def get_or_add_payment_method(payment_method_name, method_params)
    if (payment_method = self.payment_methods.where(name: payment_method_name).first).blank?
      payment_method = self.payment_methods.build(name: payment_method_name)
      payment_method.set_params(method_params)
      payment_method.save
    end
    return payment_method
  end

  def mark_success(payment_method, transaction_received_data)
    payment_method.mark_success
    self.update_attributes({:status => STATUS[:success], transaction_data: transaction_received_data})
    self.invoice.mark_paid
    subscription = self.invoice.subscription
    if subscription.plan.interval_count == 0
      subscription.start_date = Time.now.to_date
      subscription.end_date = subscription.start_date + 1000.days
    else
      subscription.start_date = Time.now.to_date
      subscription.end_date = subscription.start_date + subscription.plan.interval_count.send(subscription.plan.interval.downcase.pluralize.to_sym)
    end
    subscription.save
  end

  def mark_cancelled(payment_method, transaction_received_data)
    payment_method.mark_failure
    self.update_attributes({:status => STATUS[:canceled], transaction_data: transaction_received_data})
  end

  def mark_failure(payment_method, transaction_received_data)
    payment_method.mark_failure
    self.update_attributes({:status => STATUS[:failed], transaction_data: transaction_received_data})
  end
end
