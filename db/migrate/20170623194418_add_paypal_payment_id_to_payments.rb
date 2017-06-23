class AddPaypalPaymentIdToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :paypal_payment_id, :string
  end
end
