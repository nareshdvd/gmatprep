class AddPaymentFeeToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_fee, :float
  end
end
