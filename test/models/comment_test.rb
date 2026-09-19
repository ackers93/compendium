require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "comment-model-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Commenter",
      role: "contributor"
    )
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    @john_17 = BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    @john_4_1 = BibleVerse.create!(book: "John", chapter: 4, verse: 1, text: "When therefore the Lord", testament: "NT")
    @matt_1 = BibleVerse.create!(book: "Matthew", chapter: 1, verse: 1, text: "The book of the generation", testament: "NT")
    @note = Note.create!(title: "A note", user: @user, status: "published", content: "Body")
  end

  test "persists chapter coverage to the database" do
    comment = Comment.create!(user: @user, commentable: @john_16, content: "Chapter note", coverage: "chapter")

    assert_equal "chapter", Comment.where(id: comment.id).pick(:coverage)
  end

  test "verse_reference for chapter and book coverage" do
    chapter = Comment.create!(user: @user, commentable: @john_16, content: "Chapter note", coverage: "chapter")
    book = Comment.create!(user: @user, commentable: @john_16, content: "Book note", coverage: "book")

    assert_equal "John 3", chapter.verse_reference
    assert_equal "John", book.verse_reference
  end

  test "range comments still involve verses in the range" do
    comment = Comment.create!(user: @user, commentable: @john_16, end_verse: @john_17, content: "A range")

    assert comment.range?
    assert comment.involves_verse?(@john_16)
    assert comment.involves_verse?(@john_17)
    assert_not comment.involves_verse?(@john_4_1)
  end

  test "chapter and book comments are not verse-level" do
    chapter = Comment.create!(user: @user, commentable: @john_16, content: "Chapter note", coverage: "chapter")
    book = Comment.create!(user: @user, commentable: @john_16, content: "Book note", coverage: "book")

    assert_not chapter.involves_verse?(@john_16)
    assert_not chapter.involves_verse?(@john_17)
    assert_not book.involves_verse?(@john_16)
    assert_not book.involves_verse?(@john_4_1)
  end

  test "visible_comments excludes chapter and book comments" do
    Comment.create!(user: @user, commentable: @john_16, content: "Verse note")
    Comment.create!(user: @user, commentable: @john_16, content: "Chapter note", coverage: "chapter")
    Comment.create!(user: @user, commentable: @john_16, content: "Book note", coverage: "book")

    assert_equal 1, @john_16.visible_comments.count
    assert_equal 0, @john_17.visible_comments.count
    assert_equal 0, @john_4_1.visible_comments.count
  end

  test "rejects chapter coverage on notes" do
    comment = Comment.new(user: @user, commentable: @note, content: "Nope", coverage: "chapter")

    assert_not comment.valid?
    assert_includes comment.errors[:coverage], "can only be chapter or book for Bible comments"
  end

  test "rejects end verse on chapter comments" do
    comment = Comment.new(
      user: @user,
      commentable: @john_16,
      content: "Nope",
      coverage: "chapter",
      end_verse: @john_17
    )

    assert_not comment.valid?
    assert_includes comment.errors[:end_verse], "can't be set on chapter or book comments"
  end

  test "replies inherit parent coverage" do
    parent = Comment.create!(user: @user, commentable: @john_16, content: "Chapter note", coverage: "chapter")
    reply = Comment.create!(user: @user, commentable: @john_16, parent: parent, content: "A reply")

    assert_equal Comment::COVERAGE_CHAPTER, reply.coverage
  end
end
