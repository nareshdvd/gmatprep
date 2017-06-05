class Payment < ActiveRecord::Base
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

  after_update :start_subscription, if: :status_changed_to_paid?

  def status_changed_to_paid?
    status_was == STATUS[:success] && status == STATUS[:paid]
  end

  def start_subscription
    payment = self
    plan = payment.subscription.plan
    curr_date = Time.now.to_date
    payment.subscription.user.subscriptions.where(is_active: true).update_all({is_active: false})
    payment.subscription.update_attributes(start_date: curr_date, end_date: (curr_date + plan.interval_count.send(plan.interval.pluralize.downcase)), is_active: true)
  end

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

  def encrypted_key
    return @encrypted_key if @encrypted_key.present?
    payment = self
    plain_text = "#{payment.id}$#{payment.amount}$#{payment.currency}$#{payment.gm_txn_id}$#{payment.created_at.to_i}$#{payment.subscription.plan_id}"
    iv = AES.iv(:base_64)
    key = Gmatprep::Application.config.secret_for_encryption
    @encrypted_key = AES.encrypt(plain_text, key, {:iv => iv})
  end
end
