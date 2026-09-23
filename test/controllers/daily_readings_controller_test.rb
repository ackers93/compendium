require "test_helper"

class DailyReadingsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "reader-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Daily Reader",
      role: "viewer",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current
    )
    @plan = ReadingPlan.create!(
      slug: ReadingPlan::BIBLE_COMPANION_SLUG,
      name: "Bible Companion",
      description: "Test companion"
    )
    day = @plan.reading_plan_days.create!(month: 1, day: 1)
    day.reading_plan_passages.create!(
      slot: 1, position: 0, book: "Genesis", start_chapter: 1, end_chapter: 2
    )
    day.reading_plan_passages.create!(
      slot: 2, position: 0, book: "Psalms", start_chapter: 1, end_chapter: 2
    )
    day.reading_plan_passages.create!(
      slot: 3, position: 0, book: "Matthew", start_chapter: 1, end_chapter: 2
    )
    next_day = @plan.reading_plan_days.create!(month: 1, day: 2)
    next_day.reading_plan_passages.create!(
      slot: 1, position: 0, book: "Genesis", start_chapter: 3, end_chapter: 4
    )
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "show renders today's readings" do
    travel_to Date.new(2026, 1, 1) do
      get daily_readings_path
      assert_response :success
      assert_select "a.daily-readings-passage-link", text: "Genesis 1–2"
    end
  end

  test "show renders a specific date" do
    get daily_reading_path(date: "2026-01-01")
    assert_response :success
    assert_match "Genesis 1–2", response.body
  end

  test "show accepts date query param" do
    get daily_readings_path(date: "2026-01-01")
    assert_response :success
    assert_match "Matthew 1–2", response.body
  end

  test "show falls back to today for invalid date" do
    travel_to Date.new(2026, 1, 1) do
      get daily_readings_path(date: "not-a-date")
      assert_response :success
      assert_match "Genesis 1–2", response.body
    end
  end

  test "show explains catch-up day on Feb 29" do
    get daily_reading_path(date: "2024-02-29")
    assert_response :success
    assert_match "catch-up", response.body
  end

  test "requires authentication" do
    logout
    get daily_readings_path
    assert_redirected_to new_user_session_path
  end

  test "show uses browser time zone cookie for today" do
    # 3am UTC on Jan 2 is still 7pm on Jan 1 in America/Los_Angeles (PST).
    travel_to Time.utc(2026, 1, 2, 3, 0, 0) do
      cookies[:time_zone] = "America/Los_Angeles"
      get daily_readings_path

      assert_response :success
      assert_select "h2.section-title", text: "Thursday, January 1, 2026"
      assert_select "a.daily-readings-passage-link", text: "Genesis 1–2"
    end
  end

  test "show falls back to app time zone for invalid cookie" do
    travel_to Time.utc(2026, 1, 2, 3, 0, 0) do
      cookies[:time_zone] = "Not/A_Real_Zone"
      get daily_readings_path

      assert_response :success
      assert_select "h2.section-title", text: "Friday, January 2, 2026"
      assert_select "a.daily-readings-passage-link", text: "Genesis 3–4"
    end
  end
end
