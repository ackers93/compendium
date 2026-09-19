require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "comment-ctrl-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Comment Controller",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    @john_17 = BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "verse page offers through-verse range, not chapter or book radios" do
    get bible_verse_show_path(book: "John", chapter: 3, verse: 16)

    assert_response :success
    assert_select "input[name='comment[end_verse]']"
    assert_select "input[name='comment[coverage]']", false
    assert_match "Through verse", response.body
  end

  test "creates a ranged verse comment" do
    assert_difference -> { Comment.count }, 1 do
      post bible_verse_comments_path(book: "John", chapter: 3, verse: 16), params: {
        comment: { content: "A range note", end_verse: 17 }
      }
    end

    comment = Comment.last
    assert comment.verse_coverage?
    assert_equal @john_17, comment.end_verse
    assert_equal "John 3:16-17", comment.verse_reference
  end

  test "verse page does not list chapter or book comments" do
    Comment.create!(user: @user, commentable: @john_16, content: "About this verse")
    Comment.create!(user: @user, commentable: @john_16, content: "About this chapter", coverage: "chapter")
    Comment.create!(user: @user, commentable: @john_16, content: "About this book", coverage: "book")

    get bible_verse_show_path(book: "John", chapter: 3, verse: 16)

    assert_response :success
    assert_match "About this verse", response.body
    assert_no_match "About this chapter", response.body
    assert_no_match "About this book", response.body
  end

  test "creates a chapter comment from the chapter button" do
    assert_difference -> { Comment.count }, 1 do
      post bible_verse_comments_path(book: "John", chapter: 3, verse: 16), params: {
        return_to: "chapter",
        comment: { content: "Thoughts on the chapter", coverage: "chapter" }
      }
    end

    comment = Comment.last
    assert_equal Comment::COVERAGE_CHAPTER, comment.coverage
    assert_equal "chapter", Comment.where(id: comment.id).pick(:coverage)
    assert_nil comment.end_verse
    assert_redirected_to bible_verse_verses_path(book: "John", chapter: 3)
  end

  test "creates a book comment from the book button" do
    assert_difference -> { Comment.count }, 1 do
      post bible_verse_comments_path(book: "John", chapter: 3, verse: 16), params: {
        return_to: "book",
        comment: { content: "Thoughts on the book", coverage: "book" }
      }
    end

    comment = Comment.last
    assert_equal Comment::COVERAGE_BOOK, comment.coverage
    assert_equal "book", Comment.where(id: comment.id).pick(:coverage)
    assert_redirected_to bible_verse_chapters_path(book: "John")
  end

  test "chapter comment modal has hidden coverage and no range field" do
    get new_bible_verse_comment_path(book: "John", chapter: 3, verse: 16, coverage: "chapter", return_to: "chapter")

    assert_response :success
    assert_select "input[name='comment[coverage]'][type=hidden][value=chapter]"
    assert_select "input[name='comment[end_verse]']", false
    assert_match "Add Chapter Comment", response.body
  end

  test "chapter page shows chapter comments and add button" do
    Comment.create!(user: @user, commentable: @john_16, content: "About this chapter", coverage: "chapter")

    get bible_verse_verses_path(book: "John", chapter: 3)

    assert_response :success
    assert_match "Comments on John 3", response.body
    assert_match "About this chapter", response.body
    assert_match "Add chapter comment", response.body
  end

  test "book page shows book comments and add button" do
    Comment.create!(user: @user, commentable: @john_16, content: "About this book", coverage: "book")

    get bible_verse_chapters_path(book: "John")

    assert_response :success
    assert_match "Comments on John", response.body
    assert_match "About this book", response.body
    assert_select "a", text: "Add book comment"
  end
end
