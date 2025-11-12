class ApplicationMailer < ActionMailer::Base
  default from: ENV['GMAIL_USERNAME'] || "noreply@yourdomain.com"
  layout "mailer"
end
