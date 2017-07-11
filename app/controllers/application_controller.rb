class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to new_user_session_path, :alert => exception.message
  end

  def after_sign_in_path_for(resource)
    root_url
  end

  private
  def is_candidate?
    if !current_user.is_candidate?
      redirect_to root_path, "Please register"
    end
  end

  def in_progress_paper?
    if current_user.current_test.present?
      redirect_to papers_question_path(current_user.current_test.id, current_user.current_test.papers_questions.last.id)
    end
  end
end
