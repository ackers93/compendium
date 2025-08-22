class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role, :ecclesia])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role, :ecclesia])
  end
end
