class PaymentMethod < ActiveRecord::Base
  PAYPAL="PaypalPaymentMethod"
  PAYU="PayuPaymentMethod"
  STATUS={
    pending: 0,
    success: 1,
    failure: 2
  }

  belongs_to :payment

  self.inheritance_column = :name

  before_create :generate_unique_id

  attr_accessor :success_url, :cancel_url

  scope :paypal, ->{where(name: "PaypalPaymentMethod")}
  scope :payu, ->{where(name: "PayuPaymentMethod")}

  def mark_success
    self.status = PaymentMethod::STATUS[:success]
    self.save
  end

  def mark_failure
    self.status = PaymentMethod::STATUS[:failure]
    self.save
  end
end
