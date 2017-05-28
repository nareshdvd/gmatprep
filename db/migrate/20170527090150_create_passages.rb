class CreatePassages < ActiveRecord::Migration
  def change
    create_table :passages do |t|
      t.string :title
      t.text :description
      t.integer :question_count

      t.timestamps null: false
    end
  end
end
