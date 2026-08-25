require "test_helper"

class WeeklyDigestMailerTest < ActionMailer::TestCase
  setup do
    Rails.application.routes.default_url_options[:host] = "localhost"
    ActionMailer::Base.default_url_options[:host] = "localhost"

    @user = User.create!(
      email: "digest-reader-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Digest Reader"
    )
    @week_start = Time.zone.parse("2026-08-17").beginning_of_day
    @week_end = @week_start.end_of_week(:monday)
    @summary = [
      WeeklyDigestCollector::Section.new(
        key: :notes,
        label: "Notes",
        count: 1,
        examples: [
          WeeklyDigestCollector::Example.new(
            title: "A sample note",
            url: "http://example.com/notes/1"
          )
        ],
        contribute_path: "http://example.com/notes/new"
      ),
      WeeklyDigestCollector::Section.new(
        key: :comments,
        label: "Comments",
        count: 0,
        examples: [],
        contribute_path: "http://example.com/bible_verses/books"
      ),
      WeeklyDigestCollector::Section.new(
        key: :chiasms,
        label: "Chiasms",
        count: 0,
        examples: [],
        contribute_path: "http://example.com/chiasms/new"
      )
    ]
  end

  test "digest sends to the user with week in the subject" do
    email = WeeklyDigestMailer.digest(
      @user,
      summary: @summary,
      week_start: @week_start,
      week_end: @week_end
    )

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_match(/Compendium weekly digest/i, email.subject)
    assert_match(/Aug/, email.subject)
  end

  test "digest includes active examples, empty summary, and contribute buttons" do
    email = WeeklyDigestMailer.digest(
      @user,
      summary: @summary,
      week_start: @week_start,
      week_end: @week_end
    )
    email.deliver_now

    html = email.html_part.body.to_s
    text = email.text_part.body.to_s

    assert_match "A sample note", html
    assert_match "There were no Comments or Chiasms this week", html
    assert_match "Do you have anything to contribute?", html
    assert_match ">Comments<", html
    assert_match ">Chiasms<", html
    assert_match "A sample note", text
    assert_match(/there were no comments or chiasms this week/i, text)
    assert_match "Do you have anything to contribute?", text
    assert_match "Manage email preferences", html
    assert email.attachments["logo.png"].present?
  end
end
