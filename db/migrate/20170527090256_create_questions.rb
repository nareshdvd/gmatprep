class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :description
      t.references :level, index: true, foreign_key: true
      t.references :category, index: true, foreign_key: true
      t.references :passage, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
