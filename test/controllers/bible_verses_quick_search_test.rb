require "test_helper"

class BibleVersesQuickSearchTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "bible-search-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Bible Search User",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )

    @john_316 = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world, that he gave his only begotten Son",
      testament: "NT"
    )
    BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 8,
      text: "But God commendeth his love toward us",
      testament: "NT"
    )
  end

  teardown do
    Warden.test_reset!
  end

  test "guest is redirected to sign in" do
    get bible_verses_quick_search_path, params: { q: "love" }
    assert_redirected_to new_user_session_path
  end

  test "blank query returns empty arrays" do
    login_as @user, scope: :user

    get bible_verses_quick_search_path, params: { q: "  " }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal [], body["references"]
    assert_equal [], body["content"]
  end

  test "reference query returns verse with text" do
    login_as @user, scope: :user

    get bible_verses_quick_search_path, params: { q: "John 3:16" }
    assert_response :success

    body = JSON.parse(response.body)
    verse_hit = body["references"].find { |r| r["type"] == "verse" }
    assert_not_nil verse_hit
    assert_equal "John", verse_hit["book"]
    assert_equal 3, verse_hit["chapter"]
    assert_equal 16, verse_hit["verse"]
    assert_includes verse_hit["text"], "loved the world"
  end

  test "content query returns matching verses" do
    login_as @user, scope: :user

    get bible_verses_quick_search_path, params: { q: "loved" }
    assert_response :success

    body = JSON.parse(response.body)
    assert body["content"].any? { |r| r["book"] == "John" && r["verse"] == 16 }
    assert body["content"].all? { |r| r["type"] == "content" && r["text"].present? }
  end

  test "short queries skip content search" do
    login_as @user, scope: :user

    get bible_verses_quick_search_path, params: { q: "lo" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal [], body["content"]
  end
end
