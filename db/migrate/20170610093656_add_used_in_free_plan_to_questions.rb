class AddUsedInFreePlanToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :used_in_free_plan, :boolean, default: false
  end
end
