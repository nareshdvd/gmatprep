class LevelsController < ApplicationController
  load_and_authorize_resource
  def index
    @objects = Level.all
    respond_to do |format|
      format.html {render "shared/index"}
    end
  end

  def new
    @level = Level.new
  end

  def create
    @level = Level.new(level_params)
    @level.save
    respond_to do |format|
      format.html {redirect_to levels_path }
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
  def level_params
    params.require(:level).permit(:name, :weight)
  end
end
