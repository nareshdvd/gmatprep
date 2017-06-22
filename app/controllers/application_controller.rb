class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  layout :choose_layout

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to new_user_session_path, :alert => exception.message
  end

  def choose_layout
    if current_user
      if current_user.is_candidate?
        return "candidates"
      else
        return "application"
      end
    else
      return "public"
    end
  end
end
