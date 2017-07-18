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

  def encrypted_key
    return @encrypted_key if @encrypted_key.present?
    payment = self
    plain_text = "#{payment.id}$#{payment.amount}$#{payment.currency}$#{payment.gm_txn_id}$#{payment.created_at.to_i}$#{payment.invoice.subscription.plan_id}"
    iv = AES.iv(:base_64)
    key = Gmatprep::Application.config.secret_for_encryption
    @encrypted_key = AES.encrypt(plain_text, key, {:iv => iv})
  end

  def get_or_add_payment_method(payment_method_name, method_params)
    if (payment_method = self.payment_methods.where(name: payment_method_name).first).blank?
      payment_method = self.payment_methods.build(name: payment_method_name)
      payment_method.set_params(method_params)
      payment_method.save
    end
    return payment_method
  end

  def create_paypal_payment(success_url, cancel_url)
    payment = self
    paypal_payment = Payment.new({
      :intent => "sale",
      :payer =>  {
        :payment_method =>  "paypal"
      },
      :redirect_urls => {
        :return_url => success_url,
        :cancel_url =>  cancel_url
      },
      :transactions => [
        {
          :item_list => {
            :items => [
              {
                :name => payment.invoice.subscription.plan.name,
                :sku => payment.invoice.subscription.plan.id,
                :price => payment.invoice.subscription.plan.amount.round(2).to_s,
                :currency => payment.invoice.subscription.plan.currency.upcase,
                :quantity => 1
              }
            ]
          },
          :amount => {
            :total => payment.invoice.subscription.plan.amount.round(2).to_s,
            :currency => payment.invoice.subscription.plan.currency.upcase
          },
          :description => "Payment for Plan #{payment.invoice.subscription.plan.id}"
        }
      ]
    })
    if paypal_payment.create
      payment.paypal_payment_id = paypal_payment.id
      payment.payment_token = paypal_payment.token
      payment.save
      Rails.logger.info "Payment[#{paypal_payment.id}] created successfully"
    else
      Rails.logger.error "Error while creating payment:"
      Rails.logger.error paypal_payment.error.inspect
    end
  end

  def mark_success(payment_method)
    payment_method.mark_success
    self.update_attribute(:status, STATUS[:success])
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
end
