class PaymentMailer < ApplicationMailer
  def payment_success(user_id, payment_id)
    @user = User.find_by_id(user_id)
    @payment = Payment.where(id: payment_id).first
    if @user.present? && @payment.present?
      mail(to: @user.email, subject: 'Payment recipt')
    end
  end
end
