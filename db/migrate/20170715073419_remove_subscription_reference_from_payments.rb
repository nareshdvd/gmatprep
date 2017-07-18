class RemoveSubscriptionReferenceFromPayments < ActiveRecord::Migration
  def change
    remove_reference :payments, :subscription, index: true, foreign_key: true
  end
end
