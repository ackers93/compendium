require "test_helper"

class CommunityQuestionsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @author = User.create!(
      email: "qa-ctrl-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "QA Author",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "qa-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other Contributor",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @viewer = User.create!(
      email: "qa-viewer-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Viewer",
      role: "viewer",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current
    )
    login_as @author, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "contributor creates a question, an answer, and a reply" do
    assert_difference -> { CommunityQuestion.count }, 1 do
      post community_questions_path, params: {
        community_question: { title: "What is faith?", content: "How would you describe it?" }
      }
    end

    question = CommunityQuestion.last
    assert_equal @author, question.user
    assert_redirected_to community_question_path(question)

    login_as @other, scope: :user
    assert_difference -> { CommunityAnswer.roots.count }, 1 do
      post community_question_community_answers_path(question), params: {
        community_answer: { content: "Trust in what is promised." }
      }
    end

    answer = CommunityAnswer.last
    assert_redirected_to community_question_path(question)

    assert_difference -> { question.community_answers.where.not(parent_id: nil).count }, 1 do
      post community_question_community_answers_path(question), params: {
        community_answer: { content: "And that trust acts.", parent_id: answer.id }
      }
    end

    reply = CommunityAnswer.last
    assert_equal answer, reply.parent
    assert_equal question, reply.community_question
  end

  test "viewer cannot create a question or an answer" do
    question = CommunityQuestion.create!(user: @author, title: "Existing", content: "Already asked")
    login_as @viewer, scope: :user

    assert_no_difference -> { CommunityQuestion.count } do
      post community_questions_path, params: {
        community_question: { title: "Nope", content: "Viewers cannot ask" }
      }
    end
    assert_redirected_to root_path

    assert_no_difference -> { CommunityAnswer.count } do
      post community_question_community_answers_path(question), params: {
        community_answer: { content: "Viewers cannot answer" }
      }
    end
    assert_redirected_to root_path
  end

  test "another contributor cannot update or destroy a question or answer" do
    question = CommunityQuestion.create!(user: @author, title: "Leave this", content: "Original body")
    answer = CommunityAnswer.create!(community_question: question, user: @author, content: "Original answer")
    login_as @other, scope: :user

    patch community_question_path(question), params: {
      community_question: { title: "Hijacked", content: "Changed" }
    }
    assert_equal "Leave this", question.reload.title
    assert_redirected_to root_path

    assert_no_difference -> { CommunityQuestion.count } do
      delete community_question_path(question)
    end

    patch community_question_community_answer_path(question, answer), params: {
      community_answer: { content: "Hijacked answer" }
    }
    assert_equal "Original answer", answer.reload.content.to_plain_text.strip
    assert_redirected_to root_path

    assert_no_difference -> { CommunityAnswer.count } do
      delete community_question_community_answer_path(question, answer)
    end
  end

  test "question page lists answers and offers a topic pin" do
    question = CommunityQuestion.create!(user: @author, title: "Mercy", content: "Where do we see it?")
    CommunityAnswer.create!(community_question: question, user: @other, content: "In the prophets.")

    get community_question_path(question)

    assert_response :success
    assert_match "In the prophets.", response.body
    assert_match "Add to Topic", response.body
    assert_match "Post an answer", response.body
  end
end
