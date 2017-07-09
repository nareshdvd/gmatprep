class AddPaperFinishDisplayedToPapers < ActiveRecord::Migration
  def change
    add_column :papers, :paper_finish_displayed, :boolean, default: false
  end
end
