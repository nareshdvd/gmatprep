class AddTransactionDataToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :transaction_data, :text
  end
end
