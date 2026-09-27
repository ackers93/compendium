require "test_helper"

class DiscussionQuestionTest < ActiveSupport::TestCase
  setup do
    @author = User.create!(
      email: "dq-author-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Question Author",
      role: "contributor"
    )
    @contributor = User.create!(
      email: "dq-contributor-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Topic Contributor",
      role: "contributor"
    )
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @topic = Topic.create!(name: "Grace-#{SecureRandom.hex(3)}")
  end

  test "rejects parents that are not a verse or topic" do
    question = DiscussionQuestion.new(user: @author, questionable: @author, body: "Who is this?")

    assert_not question.valid?
    assert_includes question.errors[:questionable_type], "is not included in the list"
  end

  test "strips body and rejects blanks and overly long prompts" do
    question = DiscussionQuestion.create!(user: @author, questionable: @verse, body: "  Why this verse?  ")
    assert_equal "Why this verse?", question.body

    blank = DiscussionQuestion.new(user: @author, questionable: @verse, body: "   ")
    assert_not blank.valid?
    assert_includes blank.errors[:body], "can't be blank"

    long = DiscussionQuestion.new(user: @author, questionable: @verse, body: "a" * 1001)
    assert_not long.valid?
    assert_includes long.errors[:body], "is too long (maximum is 1000 characters)"
  end

  test "notifies topic contributors and not the author" do
    VerseTopic.create!(topic: @topic, bible_verse: @verse, user: @contributor)
    Notification.delete_all

    assert_difference -> { Notification.where(action: "topic_contribution").count }, 1 do
      DiscussionQuestion.create!(
        user: @author,
        questionable: @topic,
        body: "What does grace require of us?"
      )
    end

    notification = Notification.last
    assert_equal @contributor, notification.recipient
    assert_equal @author, notification.actor
    assert_equal "topic_contribution", notification.action
  end

  test "does not notify anyone for a verse question" do
    assert_no_difference -> { Notification.count } do
      DiscussionQuestion.create!(
        user: @author,
        questionable: @verse,
        body: "Why is this verse here?"
      )
    end
  end

  test "does not notify the author of their own topic question" do
    VerseTopic.create!(topic: @topic, bible_verse: @verse, user: @author)
    Notification.delete_all

    assert_no_difference -> { Notification.count } do
      DiscussionQuestion.create!(
        user: @author,
        questionable: @topic,
        body: "What should we notice first?"
      )
    end
  end

  test "search matches body, topic name, and verse reference" do
    on_topic = DiscussionQuestion.create!(
      user: @author,
      questionable: @topic,
      body: "How do we practice this?"
    )
    on_verse = DiscussionQuestion.create!(
      user: @author,
      questionable: @verse,
      body: "What is the world being offered?"
    )
    other_topic = Topic.create!(name: "Patience-#{SecureRandom.hex(3)}")
    DiscussionQuestion.create!(
      user: @author,
      questionable: other_topic,
      body: "Unrelated prompt"
    )

    assert_includes DiscussionQuestion.search_by_body_or_parent("practice"), on_topic
    assert_includes DiscussionQuestion.search_by_body_or_parent(@topic.name), on_topic
    assert_includes DiscussionQuestion.search_by_body_or_parent("John 3:16"), on_verse
    assert_not_includes DiscussionQuestion.search_by_body_or_parent("practice"), on_verse
  end
end
