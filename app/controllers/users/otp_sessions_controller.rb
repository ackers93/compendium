# frozen_string_literal: true

class Users::OtpSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_otp_pending
  
  # GET /users/otp/verify
  def new
    # Generate and send OTP if not already generated
    if current_user.otp_secret.blank? || current_user.otp_sent_at.nil? || current_user.otp_sent_at < Time.current - User::OTP_EXPIRY_TIME
      current_user.generate_otp
      OtpMailer.send_otp(current_user).deliver_now
    end
    # Show the OTP verification form
  end
  
  # POST /users/otp/verify
  def create
    if current_user.verify_otp(params[:otp_code])
      current_user.clear_otp
      session[:otp_verified] = true
      flash[:notice] = "Two-factor authentication successful!"
      redirect_to after_otp_verification_path
    else
      flash.now[:alert] = "Invalid or expired verification code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end
  
  # POST /users/otp/resend
  def resend
    current_user.generate_otp
    OtpMailer.send_otp(current_user).deliver_now
    flash[:notice] = "A new verification code has been sent to your email."
    redirect_to users_otp_verify_path
  end
  
  private
  
  def check_otp_pending
    # If OTP is not required or already verified, redirect
    if !current_user.otp_required? || session[:otp_verified]
      redirect_to root_path
    end
  end
  
  def after_otp_verification_path
    stored_location_for(:user) || root_path
  end
end

