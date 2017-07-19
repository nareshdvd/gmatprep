class PaymentMailerWorker
  include Sidekiq::Worker
  def perform(user_id, payment_id)
    PaymentMailer.payment_success(user_id, payment_id).deliver
  end
end
