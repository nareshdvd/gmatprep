class Category < ActiveRecord::Base
  extend CommonToModel
  has_many :questions
  PASSAGE = "Passage"
  def self.index_columns
    {
      'name' => 'Name',
    }
  end

  def self.index_actions
    {
      'new' => ['Add', 'new_category_path', :get],
      'edit' => ['Edit', 'edit_category_path', :get],
      'destroy' => ['Delete', 'category_path', :delete]
    }
  end

  def to_s
    self.name
  end

  def self.not_passage
    Category.where("name != ?", PASSAGE).sample
  end
end
