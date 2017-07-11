class AddUserReferenceToPapers < ActiveRecord::Migration
  def change
    add_reference :papers, :user, index: true, foreign_key: true
  end
end
