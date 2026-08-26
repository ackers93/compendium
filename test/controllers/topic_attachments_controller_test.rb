require "test_helper"

class TopicAttachmentsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "topic-attach-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Topic Attacher",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "topic-attach-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other Attacher",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @topic = Topic.create!(name: "Files-#{SecureRandom.hex(3)}")
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "create uploads pdf to topic" do
    assert_difference -> { TopicAttachment.count }, 1 do
      post topic_topic_attachments_path(@topic), params: {
        topic_attachment: {
          file: fixture_file_upload("sample.pdf", "application/pdf")
        }
      }
    end

    attachment = TopicAttachment.last
    assert_equal @topic, attachment.topic
    assert_equal @user, attachment.user
    assert attachment.file.attached?
    assert_redirected_to topic_path(@topic)
  end

  test "create rejects disallowed file types" do
    assert_no_difference -> { TopicAttachment.count } do
      post topic_topic_attachments_path(@topic), params: {
        topic_attachment: {
          file: fixture_file_upload("bad.exe", "application/octet-stream")
        }
      }
    end
  end

  test "destroy removes own attachment" do
    attachment = build_attachment(@user)

    assert_difference -> { TopicAttachment.count }, -1 do
      delete topic_topic_attachment_path(@topic, attachment)
    end
    assert_redirected_to topic_path(@topic)
  end

  test "destroy forbids other users attachment" do
    attachment = build_attachment(@other)

    assert_no_difference -> { TopicAttachment.count } do
      delete topic_topic_attachment_path(@topic, attachment)
    end
  end

  test "topic show lists attachments" do
    build_attachment(@user)

    get topic_path(@topic)
    assert_response :success
    assert_match "Attachments", response.body
    assert_match "study-notes.pdf", response.body
  end

  private

  def build_attachment(user)
    attachment = TopicAttachment.new(topic: @topic, user: user)
    attachment.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "study-notes.pdf",
      content_type: "application/pdf"
    )
    attachment.save!
    attachment
  end
end
