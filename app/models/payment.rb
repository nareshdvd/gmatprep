class Payment < ActiveRecord::Base
  belongs_to :subscription
  STATUS={
    :pending => "0",
    :initiated => "1",
    :paid => "2",
    :canceled => "3",
    :failed => "4"
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
end
