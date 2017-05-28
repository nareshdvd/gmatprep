class QuestionsController < ApplicationController
  load_and_authorize_resource
  def index
    @objects = Question.all
    respond_to do |format|
      format.html {render "shared/index"}
    end
  end

  def new
    @question = Question.new
    5.times {@question.options.build}
  end

  def create
    @question = Question.new(question_params)
    @question.save
    respond_to do |format|
      format.html {redirect_to questions_path }
    end
  end

  def edit
    @question = Question.find_by_id(params[:id])
    respond_to do |format|
      if @question.category.name == Category::PASSAGE
        format.html{redirect_to edit_passage_path(@question.passage)}
      else
        format.html
      end
    end
  end

  def update
    @question = Question.find_by_id(params[:id])
    @question.update_attributes(question_params)
    respond_to do |format|
      format.html {redirect_to questions_path }
    end
  end

  def destroy
  end

  private
  def question_params
    new_params = params.require(:question).permit(:description, :level_id, :category_id, options_attributes: [:id, :description, :correct])
    new_params[:options_attributes].each do |option_param|
      option_param[:correct] = "0" if option_param[:correct].blank?
    end
    new_params
  end
end