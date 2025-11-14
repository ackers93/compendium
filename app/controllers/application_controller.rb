class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_otp_requirement
  before_action :check_onboarding_requirement

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role, :ecclesia])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :role, :ecclesia])
  end
  
  # Check if user needs to verify OTP
  def check_otp_requirement
    return unless user_signed_in?
    return if controller_name == 'otp_sessions' # Don't redirect from OTP controller
    return if controller_name == 'sessions' && action_name == 'destroy' # Allow sign out
    
    if current_user.otp_required? && !session[:otp_verified]
      redirect_to users_otp_verify_path
    end
  end
  
  # Check if user needs to see onboarding
  def check_onboarding_requirement
    return unless user_signed_in?
    return if controller_name == 'onboarding' # Don't redirect from onboarding controller
    return if controller_name == 'sessions' # Don't redirect during sign in/out
    return if controller_name == 'registrations' # Don't redirect during registration
    return if controller_name == 'otp_sessions' # Don't redirect during OTP verification
    
    if current_user.needs_any_onboarding?
      redirect_to onboarding_path
    end
  end
end
