class AddPaymentTokenToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payment_token, :string
  end
end
