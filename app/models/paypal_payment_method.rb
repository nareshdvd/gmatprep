class PaypalPaymentMethod < PaymentMethod
  def url_name
    "paypal"
  end
  def set_params(method_params)
    self.success_url = method_params[:success_url]
    self.cancel_url = method_params[:cancel_url]
  end
  def generate_unique_id
    payment = self.payment
    paypal_payment = PayPal::SDK::REST::DataTypes::Payment.new({
      :intent => "sale",
      :payer =>  {
        :payment_method =>  "paypal"
      },
      :redirect_urls => {
        :return_url => self.success_url,
        :cancel_url =>  self.cancel_url
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
      self.unique_id = paypal_payment.id
      self.payment_token = paypal_payment.token
      Rails.logger.info "Payment[#{paypal_payment.id}] created successfully"
    else
      Rails.logger.error "Error while creating payment:"
      Rails.logger.error paypal_payment.error.inspect
    end
  end

  def match_token(token)
    self.payment_token == token
  end
end