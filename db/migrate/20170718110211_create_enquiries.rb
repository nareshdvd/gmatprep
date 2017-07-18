class CreateEnquiries < ActiveRecord::Migration
  def change
    create_table :enquiries do |t|
      t.string :email, limit: 100
      t.string :phone, limit: 20
      t.string :title
      t.text :message

      t.timestamps null: false
    end
  end
end
