class Level < ActiveRecord::Base
  extend CommonToModel
  EASY = 'Easy'
  MEDIUM = 'Medium'
  HARD = 'Hard'
  LEVELS = {
    1 => EASY,
    2 => MEDIUM,
    3 => HARD
  }
  has_many :questions
  def self.index_columns
    {
      'name' => 'Name',
      'weight' => 'Weight'
    }
  end

  def self.index_actions
    {
      'new' => ['Add', 'new_level_path', :get],
      'edit' => ['Edit', 'edit_level_path', :get],
      'destroy' => ['Delete', 'level_path', :delete]
    }
  end

  def to_s
    self.name
  end

  def self.easy
    Level.find_by_name(EASY)
  end

  def self.medium
    Level.find_by_name(MEDIUM)
  end

  def self.hard
    Level.find_by_name(HARD)
  end
end
