require "test_helper"

class NotificationDispatcherTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "owner-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Note Owner",
      role: "contributor"
    )
    @commenter = User.create!(
      email: "commenter-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Commenter",
      role: "contributor"
    )
    @other = User.create!(
      email: "other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other User",
      role: "contributor"
    )
    @admin = User.create!(
      email: "admin-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Admin",
      role: "admin"
    )
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @note = Note.create!(
      title: "Owned note",
      user: @owner,
      status: "published",
      content: "Note body"
    )
  end

  test "notifies note owner when someone comments" do
    comment = Comment.create!(
      user: @commenter,
      commentable: @note,
      content: "Great note"
    )

    notification = Notification.find_by(recipient: @owner, notifiable: comment, action: "comment")
    assert_not_nil notification
    assert_equal @commenter, notification.actor
    assert_nil notification.read_at
  end

  test "does not notify when user comments on their own note" do
    assert_no_difference -> { Notification.count } do
      Comment.create!(
        user: @owner,
        commentable: @note,
        content: "My own comment"
      )
    end
  end

  test "notifies parent author on reply" do
    parent = Comment.create!(
      user: @owner,
      commentable: @note,
      content: "Parent comment"
    )
    Notification.delete_all

    reply = Comment.create!(
      user: @commenter,
      commentable: @note,
      parent: parent,
      content: "A reply"
    )

    reply_notification = Notification.find_by(recipient: @owner, notifiable: reply, action: "reply")
    assert_not_nil reply_notification
    assert_equal 1, Notification.where(recipient: @owner, notifiable: reply).count
  end

  test "notifies other topic contributors when a verse is added" do
    topic = Topic.create!(name: "Faith-#{SecureRandom.hex(3)}")
    VerseTopic.create!(topic: topic, bible_verse: @verse, user: @owner)
    Notification.delete_all

    other_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 1,
      text: "Therefore being justified by faith",
      testament: "NT"
    )
    verse_topic = VerseTopic.create!(topic: topic, bible_verse: other_verse, user: @commenter)

    notification = Notification.find_by(
      recipient: @owner,
      notifiable: verse_topic,
      action: "topic_contribution"
    )
    assert_not_nil notification
    assert_equal @commenter, notification.actor
  end

  test "notifies topic contributors when content is pinned" do
    topic = Topic.create!(name: "Grace-#{SecureRandom.hex(3)}")
    VerseTopic.create!(topic: topic, bible_verse: @verse, user: @owner)
    Notification.delete_all

    topic_item = TopicItem.create!(topic: topic, user: @commenter, itemable: @note)

    notification = Notification.find_by(
      recipient: @owner,
      notifiable: topic_item,
      action: "topic_contribution"
    )
    assert_not_nil notification
    assert_equal @commenter, notification.actor
  end

  test "does not notify contributor of their own topic addition" do
    topic = Topic.create!(name: "Hope-#{SecureRandom.hex(3)}")
    VerseTopic.create!(topic: topic, bible_verse: @verse, user: @owner)
    Notification.delete_all

    other_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 8,
      verse: 28,
      text: "And we know that all things work together",
      testament: "NT"
    )

    assert_no_difference -> { @owner.notifications.count } do
      VerseTopic.create!(topic: topic, bible_verse: other_verse, user: @owner)
    end
  end

  test "notifies thread owner when someone else adds a verse" do
    thread = BibleThread.create!(title: "Salvation", user: @owner, current_editor: @owner)
    thread.bible_thread_entries.create!(bible_verse: @verse, user: @owner, position: 1)
    Notification.delete_all

    other_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 8,
      text: "But God commendeth his love toward us",
      testament: "NT"
    )
    entry = thread.bible_thread_entries.create!(bible_verse: other_verse, user: @commenter, position: 2)

    notification = Notification.find_by(
      recipient: @owner,
      notifiable: entry,
      action: "thread_contribution"
    )
    assert_not_nil notification
    assert_equal @commenter, notification.actor
  end

  test "notifies prior thread contributors when a verse is added" do
    thread = BibleThread.create!(title: "Grace", user: @owner, current_editor: @owner)
    thread.bible_thread_entries.create!(bible_verse: @verse, user: @owner, position: 1)

    second_verse = BibleVerse.create!(
      book: "Ephesians",
      chapter: 2,
      verse: 8,
      text: "For by grace are ye saved through faith",
      testament: "NT"
    )
    thread.bible_thread_entries.create!(bible_verse: second_verse, user: @commenter, position: 2)
    Notification.delete_all

    third_verse = BibleVerse.create!(
      book: "Titus",
      chapter: 2,
      verse: 11,
      text: "For the grace of God that bringeth salvation",
      testament: "NT"
    )
    entry = thread.bible_thread_entries.create!(bible_verse: third_verse, user: @other, position: 3)

    assert_not_nil Notification.find_by(recipient: @owner, notifiable: entry, action: "thread_contribution")
    assert_not_nil Notification.find_by(recipient: @commenter, notifiable: entry, action: "thread_contribution")
    assert_nil Notification.find_by(recipient: @other, notifiable: entry)
  end

  test "does not notify when thread creator adds their own verse" do
    thread = BibleThread.create!(title: "Faith", user: @owner, current_editor: @owner)
    thread.bible_thread_entries.create!(bible_verse: @verse, user: @owner, position: 1)
    Notification.delete_all

    other_verse = BibleVerse.create!(
      book: "Hebrews",
      chapter: 11,
      verse: 1,
      text: "Now faith is the substance of things hoped for",
      testament: "NT"
    )

    assert_no_difference -> { Notification.count } do
      thread.bible_thread_entries.create!(bible_verse: other_verse, user: @owner, position: 2)
    end
  end

  test "contributor can edit another users thread but not delete it" do
    thread = BibleThread.create!(title: "Shared", user: @owner)

    assert @commenter.can_edit?(thread)
    assert @commenter.can_update?(thread)
    assert_not @commenter.can_delete?(thread)
    assert @owner.can_delete?(thread)
  end

  test "notifies content author when review is requested" do
    flag = ContentFlag.create!(
      user: @other,
      flaggable: @note,
      status: "pending"
    )

    NotificationDispatcher.review_requested(flag, actor: @admin)

    notification = Notification.find_by(
      recipient: @owner,
      notifiable: flag,
      action: "review_requested"
    )
    assert_not_nil notification
    assert_equal @admin, notification.actor
  end

  test "mark_as_read updates read_at" do
    comment = Comment.create!(
      user: @commenter,
      commentable: @note,
      content: "Hello"
    )
    notification = Notification.find_by!(recipient: @owner, notifiable: comment)

    assert notification.unread?
    notification.mark_as_read!
    assert notification.read?
    assert_equal 0, @owner.unread_notifications_count
  end
end
