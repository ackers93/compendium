require "test_helper"

class CommunityQuestionTest < ActiveSupport::TestCase
  setup do
    @author = User.create!(
      email: "qa-author-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Question Author",
      role: "contributor"
    )
    @answerer = User.create!(
      email: "qa-answerer-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Answerer",
      role: "contributor"
    )
    @topic = Topic.create!(name: "Hope-#{SecureRandom.hex(3)}")
  end

  test "requires a title and a body" do
    missing_title = CommunityQuestion.new(user: @author, title: "  ", content: "A real question")
    assert_not missing_title.valid?
    assert_includes missing_title.errors[:title], "can't be blank"

    missing_body = CommunityQuestion.new(user: @author, title: "Why?", content: "")
    assert_not missing_body.valid?
    assert_includes missing_body.errors[:content], "can't be blank"

    question = CommunityQuestion.create!(user: @author, title: "  Why hope?  ", content: "What sustains it?")
    assert_equal "Why hope?", question.title
  end

  test "a reply must belong to the same question as its parent" do
    question = CommunityQuestion.create!(user: @author, title: "First", content: "One")
    other = CommunityQuestion.create!(user: @author, title: "Second", content: "Two")
    parent = CommunityAnswer.create!(community_question: other, user: @answerer, content: "Over there")

    reply = CommunityAnswer.new(
      community_question: question,
      user: @author,
      parent: parent,
      content: "This should not attach"
    )

    assert_not reply.valid?
    assert_includes reply.errors[:parent], "must belong to the same question"
  end

  test "rejects replies past the depth limit" do
    question = CommunityQuestion.create!(user: @author, title: "Deep", content: "Start")
    current = CommunityAnswer.create!(community_question: question, user: @author, content: "Answer")

    CommunityAnswer::MAX_DEPTH.times do |index|
      current = CommunityAnswer.create!(
        community_question: question,
        user: @answerer,
        parent: current,
        content: "Level #{index}"
      )
    end

    assert_equal CommunityAnswer::MAX_DEPTH, current.depth
    extra = CommunityAnswer.new(
      community_question: question,
      user: @author,
      parent: current,
      content: "Too deep"
    )
    assert_not extra.valid?
    assert_includes extra.errors[:base], "This thread can't go any deeper"
  end

  test "notifies the question author of an answer and the parent author of a reply" do
    question = CommunityQuestion.create!(user: @author, title: "Grace", content: "How does it work?")

    assert_difference -> { Notification.where(action: "answer").count }, 1 do
      @answer = CommunityAnswer.create!(community_question: question, user: @answerer, content: "It is a gift.")
    end
    assert_equal @author, Notification.last.recipient

    assert_no_difference -> { Notification.where(action: "answer").count } do
      assert_difference -> { Notification.where(action: "answer_reply").count }, 1 do
        CommunityAnswer.create!(
          community_question: question,
          user: @author,
          parent: @answer,
          content: "Say more about that."
        )
      end
    end
    assert_equal @answerer, Notification.where(action: "answer_reply").last.recipient
  end

  test "a community question can be pinned and an answer cannot" do
    question = CommunityQuestion.create!(user: @author, title: "Pinned?", content: "Please pin this.")
    pin = TopicItem.new(topic: @topic, user: @author, itemable: question)
    assert pin.valid?
    assert pin.save

    answer = CommunityAnswer.create!(community_question: question, user: @answerer, content: "Not pinnable")
    answer_pin = TopicItem.new(topic: @topic, user: @author, itemable: answer)
    assert_not answer_pin.valid?
    assert_includes answer_pin.errors[:itemable_type], "is not included in the list"
  end

  test "search matches the title and the question body" do
    match = CommunityQuestion.create!(user: @author, title: "Living water", content: "What did Jesus mean?")
    CommunityQuestion.create!(user: @author, title: "Other", content: "Unrelated")

    assert_includes CommunityQuestion.search_by_title_or_body("living"), match
    assert_includes CommunityQuestion.search_by_title_or_body("Jesus"), match
    assert_not_includes CommunityQuestion.search_by_title_or_body("unrelated"), match
  end
end
