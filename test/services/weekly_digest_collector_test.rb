require "test_helper"

class WeeklyDigestCollectorTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.default_url_options[:host] = "localhost"
    ActionMailer::Base.default_url_options[:port] = 3000

    @user = User.create!(
      email: "contributor-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Digest Contributor",
      role: "contributor"
    )
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @other_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 8,
      text: "But God commendeth his love toward us",
      testament: "NT"
    )
    @week_start = Time.zone.parse("2026-08-17 00:00:00") # Monday
    @week_end = @week_start.end_of_week(:monday)
    @range = @week_start..@week_end
    travel_to Time.zone.parse("2026-08-25 10:00:00") # Tuesday after that week
  end

  teardown do
    travel_back
  end

  test "previous_week_range is prior Monday through Sunday" do
    range = WeeklyDigestCollector.previous_week_range

    assert_equal Time.zone.parse("2026-08-17").beginning_of_day, range.begin
    assert_in_delta @week_end.to_i, range.end.to_i, 1
  end

  test "returns counts and examples for content created in the range" do
    note = Note.create!(
      title: "Weekly note",
      user: @user,
      status: "published",
      created_at: @week_start + 1.day
    )
    note.update_column(:created_at, @week_start + 1.day)

    draft = Note.create!(title: "Draft note", user: @user, status: "draft")
    draft.update_column(:created_at, @week_start + 1.day)

    comment = Comment.create!(user: @user, commentable: @verse, content: "A helpful comment about love")
    comment.update_column(:created_at, @week_start + 2.days)

    xref = CrossReference.create!(user: @user, source_verse: @verse, target_verse: @other_verse)
    xref.update_column(:created_at, @week_start + 2.days)

    topic = Topic.create!(name: "Love of God #{SecureRandom.hex(3)}")
    verse_topic = VerseTopic.create!(user: @user, bible_verse: @verse, topic: topic)
    verse_topic.update_column(:created_at, @week_start + 3.days)

    thread = BibleThread.create!(title: "Love thread", user: @user)
    thread.update_column(:created_at, @week_start + 3.days)

    chiasm = Chiasm.create!(title: "John chiasm", user: @user, start_verse: @verse, end_verse: @verse)
    chiasm.update_column(:created_at, @week_start + 4.days)

    # Outside the range — must not be counted
    old_note = Note.create!(title: "Old note", user: @user, status: "published")
    old_note.update_column(:created_at, @week_start - 2.days)

    summary = WeeklyDigestCollector.call(range: @range)
    by_key = summary.index_by(&:key)

    assert_equal 1, by_key[:notes].count
    assert_equal "Weekly note", by_key[:notes].examples.first.title
    assert_includes by_key[:notes].examples.first.url, "/notes/#{note.id}"

    assert_equal 1, by_key[:comments].count
    assert_match(/helpful comment/i, by_key[:comments].examples.first.title)

    assert_equal 1, by_key[:cross_references].count
    assert_equal xref.connection_label, by_key[:cross_references].examples.first.title

    assert_equal 1, by_key[:topics].count
    assert_match topic.name, by_key[:topics].examples.first.title
    assert_match @verse.reference, by_key[:topics].examples.first.title

    assert_equal 1, by_key[:bible_threads].count
    assert_equal "Love thread", by_key[:bible_threads].examples.first.title

    assert_equal 1, by_key[:chiasms].count
    assert_equal "John chiasm", by_key[:chiasms].examples.first.title
  end

  test "empty sections include contribute paths" do
    summary = WeeklyDigestCollector.call(range: @range)

    summary.each do |section|
      assert_equal 0, section.count
      assert_empty section.examples
      assert section.contribute_path.present?
      assert section.label.present?
    end
  end

  test "cross-reference examples include comment details" do
    xref = CrossReference.create!(user: @user, source_verse: @verse, target_verse: @other_verse)
    xref.update_column(:created_at, @week_start + 1.day)
    Comment.create!(user: @user, commentable: xref, content: "These verses illuminate each other")

    section = WeeklyDigestCollector.call(range: @range).find { |s| s.key == :cross_references }

    assert_equal 1, section.count
    assert_equal xref.connection_label, section.examples.first.title
    assert_match(/illuminate each other/i, section.examples.first.detail)
  end

  test "limits examples to three newest" do
    4.times do |i|
      note = Note.create!(title: "Note #{i}", user: @user, status: "published")
      note.update_column(:created_at, @week_start + i.hours)
    end

    notes_section = WeeklyDigestCollector.call(range: @range).find { |s| s.key == :notes }

    assert_equal 4, notes_section.count
    assert_equal 3, notes_section.examples.size
    assert_equal "Note 3", notes_section.examples.first.title
  end
end
