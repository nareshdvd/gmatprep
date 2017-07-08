class ReportsController < ApplicationController
  def index
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
    respond_to do |format|
      if @paper.papers_questions.count != 41 || @paper.papers_questions.last.unanswered?
        format.html{redirect_to root_path, notice: "This paper hasn't been finished, so report generation is not possible"}
      elsif @paper.subscription.user_id != current_user.id
        format.html{redirect_to "404NotFound"}
      else
        format.html
      end
    end
  end

  def charts
    paper_id = params[:paper_id]
    @paper = Paper.find_by(id: paper_id)
    respond_to do |format|
      if @paper.papers_questions.count != 41 || @paper.papers_questions.last.unanswered?
        format.html{redirect_to root_path, notice: "This paper hasn't been finished, so report generation is not possible"}
      elsif @paper.blank?
        format.html{redirect_to root_path, notice: "Report Not Found"}
      else
        if @paper.subscription.user_id != current_user.id
          format.html{redirect_to root_path, notice: "Report Not Found"}
        else
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
            # pdf = WickedPdf.new.pdf_from_string(
            #   render_to_string('reports/charts.html.erb',
            #     :layout => 'layouts/application.html',
            #     :javascript_delay => 5000,
            #     :page_size => nil,
            #     :page_width => '30in'
            #   )
            # )
            # send_data pdf, filename: "paper-#{@paper.id}.pdf",
            #       type: 'application/pdf',
            #       disposition: 'inline'
          end
        end
      end
    end
  end
end