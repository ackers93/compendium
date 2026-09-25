require "test_helper"

class BibleVersesChapterAnnotationsTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "chapter-ann-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Chapter Annotations User",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )

    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
  end

  teardown do
    Warden.test_reset!
  end

  test "verses page includes turbo frame for annotations" do
    login_as @user, scope: :user

    get bible_verse_verses_path(book: "John", chapter: 3)
    assert_response :success
    assert_match(/id="chapter-annotations"/, response.body)
    assert_match(%r{src="[^"]*bible_verses/John/3/annotations"}, response.body)
    assert_match(/For God so loved the world/, response.body)
    assert_match(/Loading notes/, response.body)
  end

  test "annotations endpoint returns frame with verse content" do
    login_as @user, scope: :user

    get bible_verse_chapter_annotations_path(book: "John", chapter: 3)
    assert_response :success
    assert_match(/id="chapter-annotations"/, response.body)
    assert_match(/For God so loved the world/, response.body)
    assert_no_match(/Loading notes/, response.body)
  end

  test "annotations requires authentication" do
    get bible_verse_chapter_annotations_path(book: "John", chapter: 3)
    assert_redirected_to new_user_session_path
  end
end
