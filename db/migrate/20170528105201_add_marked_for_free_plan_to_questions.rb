class AddMarkedForFreePlanToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :marked_for_free_plan, :boolean, default: false, indexed: true
  end
end
