class AddButtonHtmlToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :button_html, :text
  end
end
