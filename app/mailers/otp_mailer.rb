class OtpMailer < ApplicationMailer
  def send_otp(user)
    @user = user
    @otp_code = user.otp_secret
    @expiry_minutes = User::OTP_EXPIRY_TIME / 60
    
    mail(
      to: user.email,
      subject: 'Your Two-Factor Authentication Code'
    )
  end
end
