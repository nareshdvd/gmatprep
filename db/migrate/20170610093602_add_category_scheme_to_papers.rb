class AddCategorySchemeToPapers < ActiveRecord::Migration
  def change
    add_column :papers, :category_scheme, :string
  end
end
