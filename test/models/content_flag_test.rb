require "test_helper"

class ContentFlagTest < ActiveSupport::TestCase
  setup do
    @author = User.create!(
      email: "author-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Content Author",
      role: "contributor"
    )
    @flagger = User.create!(
      email: "flagger-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Flagger",
      role: "contributor"
    )
    @note = Note.create!(
      title: "Flaggable note",
      user: @author,
      status: "published",
      content: "Note body"
    )
  end

  test "assigning content_author_id from flaggable author on create" do
    flag = ContentFlag.create!(
      user: @flagger,
      flaggable: @note,
      status: "pending",
      reason: "Needs review"
    )

    assert_equal @author.id, flag.content_author_id
    assert_equal @author, flag.content_author
  end

  test "flagged_content_needing_review_count uses content_author_id" do
    ContentFlag.create!(
      user: @flagger,
      flaggable: @note,
      status: "review_requested",
      reason: "Please revise"
    )
    ContentFlag.create!(
      user: @flagger,
      flaggable: @note,
      status: "pending",
      reason: "Still pending"
    )

    assert_equal 1, @author.flagged_content_needing_review_count
    assert_equal 0, @flagger.flagged_content_needing_review_count
  end
end
