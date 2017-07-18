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
    self.generate_token
  end
  
  def generate_token
    payment = self.payment
    iv = AES.iv(:base_64)
    key = Gmatprep::Application.config.secret_for_encryption
    self.payment_token = AES.encrypt(plain_text, key, {:iv => iv})
  end

  def plain_text
    "#{self.unique_id}$#{payment.currency}$#{payment.created_at.to_i}$#{payment.invoice.subscription.plan_id}"
  end

  def match_token(token)
    begin
      decrypted_text = AES.decrypt(token, Gmatprep::Application.config.secret_for_encryption)
      return decrypted_text == plain_text
    rescue OpenSSL::Cipher::CipherError => ex
      return false
    end
  end
end