class PassagesController < ApplicationController
  load_and_authorize_resource
  def index
    @objects = Passage.paginate(:page => params[:page], per_page: 10)
    respond_to do |format|
      format.html {render "shared/index"}
    end
  end

  def new
    @passage = Passage.new
    @passage.title = "Testing Passage 1"
    @passage.description = "Testing Passage Description 1"
    passage_category = Category.find_by_name(Category::PASSAGE)
    4.times do |i|
      question = @passage.questions.build(category_id: passage_category.id, level_id: Level.first.id)
      question.description = "question description #{i}"
      5.times {|j| question.options.build(correct: false, description: "passage 1 question #{i} option #{j}") }
    end
  end

  def create
    @passage = Passage.new(passage_params)
    @passage.save
    respond_to do |format|
      format.html {redirect_to passages_path}
    end
  end

  def edit
    @passage = Passage.find_by_id(params[:id])
  end

  def update
    @passage = Passage.find_by_id(params[:id])
    @passage.update_attributes(passage_params)
    respond_to do |format|
      format.html {redirect_to passages_path}
    end
  end

  def destroy
  end

  private
  def passage_params
    new_params = params.require(:passage).permit(:title, :description, :question_count, questions_attributes: [:id, :description, :level_id, :question_text, :category_id, options_attributes: [:id, :description, :correct]])
    if new_params[:question_count].to_i == 3
      if new_params[:questions_attributes].is_a?(Array)
        new_params[:questions_attributes].pop()
      elsif new_params[:questions_attributes].is_a?(Hash)
        new_params[:questions_attributes].delete("3")
      end
    end
    new_params[:questions_attributes].each do |inx, question_param|
      question_param[:options_attributes].each do |option_param|
        option_param[:correct] = "0" if option_param[:correct].blank?
      end
    end
    new_params
  end
end
