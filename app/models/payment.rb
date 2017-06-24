class Payment < ActiveRecord::Base
  include PayPal::SDK::REST
  include PayPal::SDK::Core::Logging
  belongs_to :subscription
  serialize :txn_notify_data, JSON
  STATUS={
    :pending => "0",
    :initiated => "1",
    :success => "2",
    :paid => "3",
    :canceled => "4",
    :failed => "5"
  }

  def pending?
    self.status == STATUS[:pending]
  end

  def initiated?
    self.status == STATUS[:initiated]
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
    plain_text = "#{payment.id}$#{payment.amount}$#{payment.currency}$#{payment.gm_txn_id}$#{payment.created_at.to_i}$#{payment.subscription.plan_id}"
    iv = AES.iv(:base_64)
    key = Gmatprep::Application.config.secret_for_encryption
    @encrypted_key = AES.encrypt(plain_text, key, {:iv => iv})
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
                :name => payment.subscription.plan.name,
                :sku => payment.subscription.plan.id,
                :price => payment.subscription.plan.amount.round(2).to_s,
                :currency => payment.subscription.plan.currency.upcase,
                :quantity => 1
              }
            ]
          },
          :amount => {
            :total => payment.subscription.plan.amount.round(2).to_s,
            :currency => payment.subscription.plan.currency.upcase
          },
          :description => "Payment for Plan #{payment.subscription.plan.id}"
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

  def paypal_request_url(success_url, cancel_url)
    return ""
    if !self.paid? && !self.success?
      request = Paypal::Express::Request.new(
        :username   => "naresh.dwivedi1987-facilitator_api1.gmail.com",
        :password   => "1393934793",
        :signature  => "AFcWxV21C7fd0v3bYYYRCpSSRl31Aj.tDgmjGvrcNGqxHlgNw2cnnkMT"
      )
      payment_request = Paypal::Payment::Request.new(
        :currency_code => self.subscription.plan.currency.upcase.to_sym,
        :amount => self.subscription.plan.amount,
        :items => [{
          :name => self.subscription.plan.name,
          :description => "",
          :amount => self.subscription.plan.amount,
          :category => :Digital
        }]
      )
      response = request.setup(
        payment_request,
        success_url,
        cancel_url,
        :no_shipping => true
      )
      return response.popup_uri
    end
  end
end
