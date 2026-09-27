require "test_helper"

class DiscussionQuestionsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @contributor = User.create!(
      email: "dq-ctrl-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Discussion Contributor",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "dq-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other Contributor",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @viewer = User.create!(
      email: "dq-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Viewer",
      role: "viewer",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current
    )
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @topic = Topic.create!(name: "Mercy-#{SecureRandom.hex(3)}")
    login_as @contributor, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "contributor creates a question on a verse" do
    assert_difference -> { DiscussionQuestion.count }, 1 do
      post bible_verse_discussion_questions_path(book: "John", chapter: 3, verse: 16), params: {
        discussion_question: { body: "What does love require here?" }
      }
    end

    question = DiscussionQuestion.last
    assert_equal @verse, question.questionable
    assert_equal @contributor, question.user
    assert_redirected_to bible_verse_show_path(book: "John", chapter: 3, verse: 16, anchor: "discussion_question_#{question.id}")
  end

  test "contributor creates a question on a topic" do
    assert_difference -> { DiscussionQuestion.count }, 1 do
      post topic_discussion_questions_path(@topic), params: {
        discussion_question: { body: "Where do we see mercy in this topic?" }
      }
    end

    question = DiscussionQuestion.last
    assert_equal @topic, question.questionable
    assert_redirected_to topic_path(@topic, anchor: "discussion_question_#{question.id}")
  end

  test "viewer cannot create a discussion question" do
    login_as @viewer, scope: :user

    assert_no_difference -> { DiscussionQuestion.count } do
      post bible_verse_discussion_questions_path(book: "John", chapter: 3, verse: 16), params: {
        discussion_question: { body: "Viewers should not post this" }
      }
    end

    assert_redirected_to root_path
  end

  test "author can update and destroy a question" do
    question = DiscussionQuestion.create!(
      user: @contributor,
      questionable: @topic,
      body: "Original prompt"
    )

    patch discussion_question_path(question), params: {
      discussion_question: { body: "Revised prompt" }
    }

    assert_equal "Revised prompt", question.reload.body
    assert_redirected_to topic_path(@topic, anchor: "discussion_question_#{question.id}")

    assert_difference -> { DiscussionQuestion.count }, -1 do
      delete discussion_question_path(question)
    end

    assert_redirected_to topic_path(@topic)
  end

  test "another contributor cannot update or destroy a question" do
    question = DiscussionQuestion.create!(
      user: @contributor,
      questionable: @verse,
      body: "Leave this prompt alone"
    )
    login_as @other, scope: :user

    patch discussion_question_path(question), params: {
      discussion_question: { body: "Hijacked prompt" }
    }

    assert_equal "Leave this prompt alone", question.reload.body
    assert_redirected_to root_path

    assert_no_difference -> { DiscussionQuestion.count } do
      delete discussion_question_path(question)
    end

    assert_redirected_to root_path
  end

  test "verse and topic pages list discussion questions" do
    DiscussionQuestion.create!(user: @contributor, questionable: @verse, body: "Verse prompt for the group")
    DiscussionQuestion.create!(user: @contributor, questionable: @topic, body: "Topic prompt for the group")

    get bible_verse_show_path(book: "John", chapter: 3, verse: 16)
    assert_response :success
    assert_match "Discussion Questions", response.body
    assert_match "Verse prompt for the group", response.body

    get topic_path(@topic)
    assert_response :success
    assert_match "Topic prompt for the group", response.body
    assert_match "Prompts for people running discussion groups.", response.body
  end
end
