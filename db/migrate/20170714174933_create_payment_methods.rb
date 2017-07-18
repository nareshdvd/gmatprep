class CreatePaymentMethods < ActiveRecord::Migration
  def change
    create_table :payment_methods do |t|
      t.string :name, index: true
      t.references :payment, index: true, foreign_key: true
      t.integer :status, index: true
      t.string :unique_id, index: true

      t.timestamps null: false
    end
  end
end
