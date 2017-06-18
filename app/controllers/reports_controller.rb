class ReportsController < ApplicationController

  def index
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
    respond_to do |format|
      if @paper.subscription.user_id != current_user.id
        format.html{redirect_to "404NotFound"}
      else
        format.html
      end
    end
  end

  def charts
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
  end
end