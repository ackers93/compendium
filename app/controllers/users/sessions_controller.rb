# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    
    if resource.otp_required?
      # Generate and send OTP
      resource.generate_otp
      OtpMailer.send_otp(resource).deliver_now
      
      # Mark session as pending OTP verification
      session[:otp_verified] = false
      
      # Sign in but redirect to OTP verification
      sign_in(resource_name, resource)
      respond_with resource, location: users_otp_verify_path
    else
      # Normal sign in without 2FA
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end
  
  # DELETE /resource/sign_out
  def destroy
    # Clear OTP verification on sign out
    session.delete(:otp_verified)
    super
  end
end
