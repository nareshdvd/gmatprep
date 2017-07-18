class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :subscription, index: true, foreign_key: true
      t.integer :status, default: 0

      t.timestamps null: false
    end
  end
end
