class AddTxnNotifyDataToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :txn_notify_data, :text
  end
end
