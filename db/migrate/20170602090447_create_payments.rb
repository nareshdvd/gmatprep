class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :txn_id
      t.string :status
      t.float :amount
      t.string :currency
      t.string :gm_txn_id
      t.references :subscription, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
