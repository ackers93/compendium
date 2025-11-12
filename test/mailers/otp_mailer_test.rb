require "test_helper"

class OtpMailerTest < ActionMailer::TestCase
  test "send_otp" do
    mail = OtpMailer.send_otp
    assert_equal "Send otp", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
