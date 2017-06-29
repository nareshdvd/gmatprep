class AdminsController < ApplicationController
  layout :admin_choose_layout, only: [:question]
  def question
    respond_to do |format|
      if current_user.roles.where(name: 'admin').blank?
        format.html {redirect_to root_path, notice: "404 not found"}
      else
        if request.method == "GET"
          id = params[:id]
          question = Question.find_by_id(id)
          @paper_question = question.papers_questions.build
          format.html
        elsif request.method == "POST"
          id = params[:id]
          next_question_id = Question.select("id").where("id > ? ", id).order("id asc").first.id;
          format.html {redirect_to admin_question_path(next_question_id) }
        else
          format.html {redirect_to root_path, notice: "404 not found"}
        end
      end
    end
  end
  
  private
  def admin_choose_layout
    return "candidates"
  end
end