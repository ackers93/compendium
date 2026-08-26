require "test_helper"

class TopicAttachmentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "attach-user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Attach User",
      role: "contributor"
    )
    @topic = Topic.create!(name: "Attachments-#{SecureRandom.hex(3)}")
  end

  test "accepts image attachments" do
    attachment = TopicAttachment.new(topic: @topic, user: @user)
    attachment.file.attach(
      io: StringIO.new("fake-png-bytes"),
      filename: "test_image.png",
      content_type: "image/png"
    )
    assert attachment.valid?, attachment.errors.full_messages.to_sentence
  end

  test "accepts pdf attachments" do
    attachment = TopicAttachment.new(topic: @topic, user: @user)
    attachment.file.attach(
      io: StringIO.new("%PDF-1.4 sample"),
      filename: "notes.pdf",
      content_type: "application/pdf"
    )
    assert attachment.valid?, attachment.errors.full_messages.to_sentence
  end

  test "accepts word attachments" do
    attachment = TopicAttachment.new(topic: @topic, user: @user)
    attachment.file.attach(
      io: StringIO.new("PK word doc"),
      filename: "study.docx",
      content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )
    assert attachment.valid?, attachment.errors.full_messages.to_sentence
  end

  test "rejects disallowed content types" do
    attachment = TopicAttachment.new(topic: @topic, user: @user)
    attachment.file.attach(
      io: StringIO.new("not allowed"),
      filename: "script.exe",
      content_type: "application/octet-stream"
    )
    assert_not attachment.valid?
    assert_includes attachment.errors[:file], "must be an image, PDF, or Word document"
  end

  test "requires a file" do
    attachment = TopicAttachment.new(topic: @topic, user: @user)
    assert_not attachment.valid?
    assert_includes attachment.errors[:file], "can't be blank"
  end
end
