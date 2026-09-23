require "test_helper"

class ContentTransferTest < ActiveSupport::TestCase
  setup do
    @admin = create_user("admin", role: "admin")
    @author = create_user("author")
    @source = "transfer-test-#{SecureRandom.hex(4)}"
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @end_verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 17,
      text: "For God sent not his Son",
      testament: "NT"
    )
  end

  test "round-trips notes including tags and status" do
    note = Note.create!(
      user: @author,
      title: "Kingdom",
      status: "draft",
      content: "<div>The kingdom of God is at hand</div>",
      tag_list: ["kingdom", "gospel"]
    )

    json = export_type("notes")
    note.destroy!

    result = import_type("notes", json)
    assert_equal 1, result.imported_count, result.errors.inspect

    restored = Note.find_by!(title: "Kingdom")
    assert_equal @author.id, restored.user_id
    assert_equal "draft", restored.status
    assert_includes restored.tag_list, "kingdom"
    assert_includes restored.tag_list, "gospel"
    assert_match(/kingdom of God/, restored.content.to_plain_text)
  end

  test "assigns missing authors to the importing admin" do
    Note.create!(
      user: @author,
      title: "Orphaned",
      status: "published",
      content: "<div>Body</div>"
    )
    json = export_type("notes")
    Note.delete_all
    @author.destroy!

    result = import_type("notes", json)
    assert_equal 1, result.imported_count
    assert_includes result.missing_authors, @author.email
    assert_equal @admin.id, Note.find_by!(title: "Orphaned").user_id
  end

  test "skips duplicate notes on re-import" do
    Note.create!(user: @author, title: "Same", status: "published", content: "<div>Once</div>")
    json = export_type("notes")

    result = import_type("notes", json)
    assert_equal 0, result.imported_count
    assert_equal 1, result.skipped_count
    assert_equal 1, Note.where(title: "Same").count
  end

  test "round-trips verse comments including ranges and replies" do
    parent = Comment.create!(
      user: @author,
      commentable: @verse,
      end_verse: @end_verse,
      content: "<div>Range comment</div>"
    )
    Comment.create!(
      user: @author,
      commentable: @verse,
      parent: parent,
      content: "<div>A reply</div>"
    )

    json = export_type("comments")
    Comment.delete_all

    result = import_type("comments", json)
    assert_equal 2, result.imported_count, result.errors.inspect

    restored = Comment.roots.find_by!(commentable: @verse)
    assert_equal @end_verse, restored.end_verse
    assert_match(/Range comment/, restored.content.to_plain_text)
    assert_equal 1, restored.replies.count
    assert_match(/A reply/, restored.replies.first.content.to_plain_text)
  end

  test "comments on notes fail until notes are imported" do
    note = Note.create!(user: @author, title: "Host", status: "published", content: "<div>Host body</div>")
    Comment.create!(user: @author, commentable: note, content: "<div>On the note</div>")

    notes_json = export_type("notes")
    comments_json = export_type("comments")
    Comment.delete_all
    Note.delete_all

    result = import_type("comments", comments_json)
    assert_equal 1, result.failed_count
    assert_match(/Import notes first/, result.errors.first[:error])

    import_type("notes", notes_json)
    result = import_type("comments", comments_json)
    assert_equal 1, result.imported_count, result.errors.inspect
    restored_note = Note.find_by!(title: "Host")
    assert_equal 1, restored_note.comments.count
  end

  test "round-trips cross-references" do
    CrossReference.create!(
      user: @author,
      source_verse: @verse,
      target_verse: @end_verse
    )

    json = export_type("cross_references")
    CrossReference.delete_all

    result = import_type("cross_references", json)
    assert_equal 1, result.imported_count, result.errors.inspect
    restored = CrossReference.find_by!(source_verse: @verse, target_verse: @end_verse)
    assert_equal @author.id, restored.user_id
  end

  test "round-trips topics and verse explanations" do
    topic = Topic.create!(name: "Faith-#{SecureRandom.hex(3)}")
    verse_topic = VerseTopic.create!(topic: topic, bible_verse: @verse, user: @author)
    verse_topic.update!(explanation: "<div>Believe</div>")

    json = export_type("topics")
    topic.destroy!

    result = import_type("topics", json)
    assert result.imported_count >= 1, result.errors.inspect

    restored = Topic.find_by("LOWER(name) = ?", topic.name.downcase)
    assert_not_nil restored
    link = restored.verse_topics.find_by!(bible_verse: @verse, user: @author)
    assert_match(/Believe/, link.explanation.to_plain_text)
  end

  test "round-trips threads and entries" do
    thread = BibleThread.create!(title: "Promise", user: @author, current_editor: @author)
    thread.bible_thread_entries.create!(bible_verse: @verse, user: @author, position: 1, comment: "First")
    thread.bible_thread_entries.create!(bible_verse: @end_verse, user: @author, position: 2, comment: "Second")

    json = export_type("threads")
    thread.destroy!

    result = import_type("threads", json)
    assert_equal 1, result.imported_count, result.errors.inspect

    restored = BibleThread.find_by!(title: "Promise", user: @author)
    assert_equal [@verse.id, @end_verse.id], restored.bible_thread_entries.order(:position).map(&:bible_verse_id)
    assert_equal ["First", "Second"], restored.bible_thread_entries.order(:position).map(&:comment)
  end

  test "round-trips chiasms and limbs" do
    chiasm = Chiasm.create!(
      user: @author,
      title: "Beloved",
      start_verse: @verse,
      end_verse: @end_verse
    )
    passage = chiasm.passage_text
    midpoint = passage.length / 2
    chiasm.chiasm_limbs.create!(position: 1, start_offset: 0, end_offset: midpoint, note: "A")
    chiasm.chiasm_limbs.create!(position: 2, start_offset: midpoint, end_offset: passage.length, note: "A'")

    json = export_type("chiasms")
    chiasm.destroy!

    result = import_type("chiasms", json)
    assert_equal 1, result.imported_count, result.errors.inspect

    restored = Chiasm.find_by!(title: "Beloved", user: @author)
    assert_equal @verse, restored.start_verse
    assert_equal @end_verse, restored.end_verse
    assert_equal ["A", "A'"], restored.chiasm_limbs.order(:position).map(&:note)
  end

  test "round-trips content tables and remaps embeds in notes" do
    table = ContentTable.create!(
      user: @author,
      title: "Comparison",
      row_count: 1,
      column_count: 1,
      cells: [["Hello"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )
    note = Note.create!(
      user: @author,
      title: "With table",
      status: "published",
      content: %Q(<div>See table</div><action-text-attachment sgid="#{table.attachable_sgid}" content-type="#{table.attachable_content_type}"></action-text-attachment>)
    )

    tables_json = export_type("content_tables")
    notes_json = export_type("notes")
    assert_includes notes_json, "data-content-table-export-id"
    assert_not_includes JSON.parse(notes_json).dig("records", 0, "content_html").to_s, table.attachable_sgid.to_s

    note.destroy!
    table.destroy!

    assert_equal 1, import_type("content_tables", tables_json).imported_count
    result = import_type("notes", notes_json)
    assert_equal 1, result.imported_count, result.errors.inspect

    restored_note = Note.find_by!(title: "With table")
    restored_table = ContentTable.find_by!(title: "Comparison", user: @author)
    assert_includes restored_note.content.body.attachables, restored_table
  end

  test "strips inline images from exported HTML" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake-png"),
      filename: "inline.png",
      content_type: "image/png"
    )
    Note.create!(
      user: @author,
      title: "Illustrated",
      status: "published",
      content: %Q(<div>Hello <action-text-attachment sgid="#{blob.attachable_sgid}" content-type="image/png"></action-text-attachment></div>)
    )

    json = export_type("notes")
    html = JSON.parse(json).dig("records", 0, "content_html").to_s
    assert_no_match(/action-text-attachment/, html)
    assert_match(/Hello/, html)
  end

  test "round-trips topic pins after notes and topics" do
    topic = Topic.create!(name: "Pins-#{SecureRandom.hex(3)}")
    note = Note.create!(user: @author, title: "Pinned note", status: "published", content: "<div>Pin me</div>")
    TopicItem.create!(topic: topic, user: @author, itemable: note, note: "<div>Why</div>")

    notes_json = export_type("notes")
    topics_json = export_type("topics")
    pins_json = export_type("topic_items")

    TopicItem.delete_all
    note.destroy!
    topic.destroy!

    import_type("notes", notes_json)
    import_type("topics", topics_json)
    result = import_type("topic_items", pins_json)
    assert_equal 1, result.imported_count, result.errors.inspect

    restored_note = Note.find_by!(title: "Pinned note")
    restored_topic = Topic.find_by!(name: topic.name)
    item = TopicItem.find_by!(topic: restored_topic, itemable: restored_note, user: @author)
    assert_match(/Why/, item.note.to_plain_text)
  end

  test "does not send notifications while importing" do
    note = Note.create!(user: @author, title: "Quiet", status: "published", content: "<div>Body</div>")
    Comment.create!(user: @admin, commentable: note, content: "<div>Imported comment</div>")
    json = export_type("comments")
    Comment.delete_all
    Notification.delete_all

    assert_no_difference -> { Notification.count } do
      import_type("comments", json)
    end
  end

  test "zip export contains every type file" do
    zip = ContentTransfer.export_zip(source: @source)
    assert_equal "PK", zip[0, 2]
    ContentTransfer.type_keys.each do |key|
      assert_includes zip, "compendium-#{key}.json"
    end
  end

  private

  def create_user(label, role: "contributor")
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: label.capitalize,
      role: role,
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
  end

  def export_type(type)
    ContentTransfer.export(type, source: @source)
  end

  def import_type(type, json)
    ContentTransfer.import(json, type: type, admin: @admin)
  end
end
