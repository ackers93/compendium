require "test_helper"

class AdminNotificationMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      email: 'newuser@example.com',
      password: 'password123',
      name: 'Test User',
      ecclesia: 'Test Ecclesia',
      role: 'viewer'
    )
    ENV['HEAD_ADMIN_EMAIL'] = 'admin@example.com'
  end

  teardown do
    ENV.delete('HEAD_ADMIN_EMAIL')
  end

  test "new_user_signup sends email to head admin" do
    email = AdminNotificationMailer.new_user_signup(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['admin@example.com'], email.to
    assert_equal "New User Signup: #{@user.email}", email.subject
    assert_match @user.email, email.body.encoded
    assert_match @user.name, email.body.encoded
    assert_match @user.ecclesia, email.body.encoded
  end

  test "new_user_signup does not send email when HEAD_ADMIN_EMAIL is not set" do
    ENV.delete('HEAD_ADMIN_EMAIL')
    
    email = AdminNotificationMailer.new_user_signup(@user)

    assert_no_emails do
      email.deliver_now
    end
  end

  test "email includes user information" do
    email = AdminNotificationMailer.new_user_signup(@user)
    email.deliver_now

    assert_match "Email: #{@user.email}", email.text_part.body.to_s
    assert_match @user.role.titleize, email.text_part.body.to_s
    assert_match "User ID: ##{@user.id}", email.text_part.body.to_s
  end

  test "email includes html and text parts" do
    email = AdminNotificationMailer.new_user_signup(@user)
    email.deliver_now

    assert_not_nil email.html_part
    assert_not_nil email.text_part
    assert_match 'New User Signup', email.html_part.body.to_s
    assert_match 'New User Signup', email.text_part.body.to_s
  end
end

