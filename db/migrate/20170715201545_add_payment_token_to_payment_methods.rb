class AddPaymentTokenToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :payment_token, :string
  end
end
