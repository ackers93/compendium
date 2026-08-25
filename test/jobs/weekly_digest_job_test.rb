require "test_helper"

class WeeklyDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.default_url_options[:host] = "localhost"

    @enabled = User.create!(
      email: "digest-on-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      weekly_digest_enabled: true
    )
    @disabled = User.create!(
      email: "digest-off-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      weekly_digest_enabled: false
    )
  end

  test "emails only users with weekly_digest_enabled" do
    assert_emails 1 do
      WeeklyDigestJob.perform_now(now: Time.zone.parse("2026-08-25 10:00:00"))
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal [@enabled.email], email.to
  end
end
