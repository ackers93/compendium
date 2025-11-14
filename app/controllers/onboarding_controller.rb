class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_onboarding_needed
  
  def show
    @onboarding_type = determine_onboarding_type
  end
  
  def complete
    case params[:type]
    when 'user'
      current_user.complete_user_onboarding!
      flash[:notice] = "Welcome to Compendium! Let's get started."
      redirect_to root_path
    when 'admin'
      current_user.complete_admin_onboarding!
      flash[:notice] = "Admin features unlocked! You now have full access to user management."
      redirect_to admin_users_path
    else
      redirect_to root_path
    end
  end
  
  def skip
    case params[:type]
    when 'user'
      current_user.complete_user_onboarding!
    when 'admin'
      current_user.complete_admin_onboarding!
    end
    redirect_to root_path
  end
  
  private
  
  def check_onboarding_needed
    unless current_user.needs_any_onboarding?
      redirect_to root_path
    end
  end
  
  def determine_onboarding_type
    # Admin onboarding takes priority if both are needed
    if current_user.needs_admin_onboarding?
      'admin'
    elsif current_user.needs_user_onboarding?
      'user'
    end
  end
end

