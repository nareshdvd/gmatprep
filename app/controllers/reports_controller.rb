class ReportsController < ApplicationController
  before_filter :find_paper, :check_unfinished
  def index
    respond_to do |format|
      format.html
    end
  end

  def charts
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: 'file_name.pdf',
        template: 'reports/charts.html.erb',
        layout: 'pdf',
        orientation: 'Landscape',
        page_size: nil,
        page_width: '25in',
        show_as_html: params.key?('debug'),
        javascript_delay: 10000
      end
    end
  end

  private
  
  def find_paper
    @paper = Paper.where(id: paper_id).first
    if (@paper.blank? || @paper.subscription.user_id != current_user.id) && !current_user.is_admin?
      raise ActiveRecord::RecordNotFound
    end
  end

  def check_unfinished
    redirect_to root_path, alert: "This paper hasn't been finished, so report generation is not possible" if @paper.unfinished?
    redirect_to root_path, alert: "You haven't answered all the questions so report generation is not possible" if !@paper.all_answered?
  end

  def paper_id
    params[:paper_id]
  end
end