class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to new_user_session_path, :alert => exception.message
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound, with: lambda { |exception| render_error 404, exception }
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

  def render_error(status, exception)
    Rails.logger.error status.to_s + " " + exception.message.to_s
    Rails.logger.error exception.backtrace.join("\n") 
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.all { render nothing: true, status: status }
    end
  end

  def current_role
    if current_user.present?
      @current_role ||= current_user.roles.first.name
    end
  end

  def user_is_admin?
    current_role == "admin"
  end

  def user_is_candidate?
    current_role == "candidate"
  end

  def redirect_js(redirect_to_url)
    respond_to do |format|
      @redirect_to = redirect_to_url
      format.js { render "shared/redirect" }
    end
  end
end
