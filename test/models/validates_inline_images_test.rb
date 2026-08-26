require "test_helper"

class ValidatesInlineImagesTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "inline-img-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Inline User",
      role: "contributor"
    )
  end

  test "note accepts inline image blob attachable" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake-png"),
      filename: "inline.png",
      content_type: "image/png"
    )
    note = Note.new(title: "With image", user: @user, status: "draft")
    note.content = "<div>Hello <action-text-attachment sgid=\"#{blob.attachable_sgid}\"></action-text-attachment></div>"
    assert note.valid?, note.errors.full_messages.to_sentence
  end

  test "note rejects non-image inline attachments" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("%PDF"),
      filename: "doc.pdf",
      content_type: "application/pdf"
    )
    note = Note.new(title: "With pdf", user: @user, status: "draft")
    note.content = "<div><action-text-attachment sgid=\"#{blob.attachable_sgid}\"></action-text-attachment></div>"
    assert_not note.valid?
    assert_includes note.errors[:base], "Inline attachments must be images (PNG, JPEG, GIF, or WebP)"
  end

  test "comment rejects non-image inline attachments" do
    note = Note.create!(title: "Parent", user: @user, status: "published", content: "Body")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("exe"),
      filename: "x.exe",
      content_type: "application/octet-stream"
    )
    comment = Comment.new(user: @user, commentable: note)
    comment.content = "<div><action-text-attachment sgid=\"#{blob.attachable_sgid}\"></action-text-attachment></div>"
    assert_not comment.valid?
    assert_includes comment.errors[:base], "Inline attachments must be images (PNG, JPEG, GIF, or WebP)"
  end
end
