class PayuPaymentMethod < PaymentMethod
  def url_name
    "payu"
  end
  def set_params(method_params)
    self.success_url = method_params[:success_url]
    self.cancel_url = method_params[:cancel_url]
  end

  def generate_unique_id
    payment = self.payment
    invoice = payment.invoice
    self.unique_id = "#{invoice.id}-#{payment.id}"
  end

  #nothing to be matched as the payuindia gem is already checking for the data we receive after payment through payu.
  def match_token(token)
    return true
  end
end