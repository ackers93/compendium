# frozen_string_literal: true

class Users::TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!
  
  # PATCH /users/two_factor_settings
  def update
    if current_user.update(otp_required_for_login: params[:enabled] == "true")
      flash[:notice] = if current_user.otp_required_for_login?
        "Two-factor authentication has been enabled."
      else
        "Two-factor authentication has been disabled."
      end
    else
      flash[:alert] = "Failed to update two-factor authentication settings."
    end
    
    redirect_back(fallback_location: root_path)
  end
end

