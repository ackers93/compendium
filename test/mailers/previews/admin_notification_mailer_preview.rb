# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/admin_notification_mailer/new_user_signup
  def new_user_signup
    user = User.new(
      id: 123,
      email: 'john.smith@example.com',
      name: 'John Smith',
      ecclesia: 'Springfield Christadelphian Ecclesia',
      role: 'viewer',
      created_at: Time.current
    )
    
    # Set HEAD_ADMIN_EMAIL for preview
    ENV['HEAD_ADMIN_EMAIL'] ||= 'admin@compendium.com'
    
    AdminNotificationMailer.new_user_signup(user)
  end
end

