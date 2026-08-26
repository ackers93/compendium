require "test_helper"

class TopicItemTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "pin-user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Pin User",
      role: "contributor"
    )
    @other = User.create!(
      email: "pin-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other User",
      role: "contributor"
    )
    @topic = Topic.create!(name: "Faith-#{SecureRandom.hex(3)}")
    @note = Note.create!(
      title: "Published note",
      user: @user,
      status: "published",
      content: "Note body"
    )
  end

  test "pins a published note to a topic" do
    item = TopicItem.create!(topic: @topic, user: @user, itemable: @note)
    assert item.persisted?
    assert_equal "Note", item.itemable_type
  end

  test "rejects draft notes" do
    draft = Note.create!(
      title: "Draft note",
      user: @user,
      status: "draft",
      content: "Draft body"
    )
    item = TopicItem.new(topic: @topic, user: @user, itemable: draft)
    assert_not item.valid?
    assert_includes item.errors[:itemable], "must be published before pinning to a topic"
  end

  test "rejects duplicate pin by same user" do
    TopicItem.create!(topic: @topic, user: @user, itemable: @note)
    duplicate = TopicItem.new(topic: @topic, user: @user, itemable: @note)
    assert_not duplicate.valid?
  end

  test "allows different users to pin the same item" do
    TopicItem.create!(topic: @topic, user: @user, itemable: @note)
    other_pin = TopicItem.new(topic: @topic, user: @other, itemable: @note)
    assert other_pin.valid?
  end

  test "rejects unknown itemable types" do
    item = TopicItem.new(topic: @topic, user: @user, itemable_type: "User", itemable_id: @user.id)
    assert_not item.valid?
    assert_includes item.errors[:itemable_type], "is not included in the list"
  end

  test "visible_to hides draft notes from strangers" do
    draft = Note.create!(
      title: "Secret draft",
      user: @user,
      status: "draft",
      content: "Secret"
    )
    # Bypass validation for visibility edge case (status changed after pin)
    item = TopicItem.new(topic: @topic, user: @user, itemable: @note)
    item.save!
    item.update_column(:itemable_id, draft.id)

    assert item.visible_to?(@user)
    assert_not item.visible_to?(@other)
    assert_not item.visible_to?(nil)
  end

  test "pins threads chiasms comments and cross references" do
    verse = BibleVerse.create!(
      book: "John",
      chapter: 1,
      verse: 1,
      text: "In the beginning",
      testament: "NT"
    )
    thread = BibleThread.create!(title: "Thread", user: @user)
    chiasm = Chiasm.create!(title: "Chiasm", user: @user, start_verse: verse, end_verse: verse)
    comment = Comment.create!(user: @user, commentable: @note, content: "A comment")
    xref = CrossReference.create!(user: @user, source_verse: verse, target_verse: BibleVerse.create!(
      book: "John", chapter: 1, verse: 2, text: "The same", testament: "NT"
    ))

    [thread, chiasm, comment, xref].each do |record|
      item = TopicItem.create!(topic: @topic, user: @user, itemable: record)
      assert item.persisted?, "Expected #{record.class.name} to pin"
    end
  end
end
