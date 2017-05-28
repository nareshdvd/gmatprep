class CategoriesController < ApplicationController
  load_and_authorize_resource
  def index
    @objects = Category.all
    respond_to do |format|
      format.html {render "shared/index"}
    end
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.save
    respond_to do |format|
      format.html {redirect_to categories_path }
    end
  end

  def edit
  end

  def update
    @category = Category.find_by_id(params[:id])
    @category.update_attributes(category_params)
    respond_to do |format|
      format.html {redirect_to categories_path }
    end
  end

  def destroy
  end

  private
  def category_params
    params.require(:category).permit(:name)
  end
end
