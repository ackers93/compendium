class AdminNotificationMailer < ApplicationMailer
  def new_user_signup(user)
    @user = user
    @admin_email = ENV['HEAD_ADMIN_EMAIL']
    
    # Only send if HEAD_ADMIN_EMAIL is configured
    return unless @admin_email.present?
    
    mail(
      to: @admin_email,
      subject: "New User Signup: #{user.email}"
    )
  end
end

