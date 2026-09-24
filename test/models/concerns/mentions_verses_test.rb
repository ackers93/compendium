# frozen_string_literal: true

require "test_helper"

class MentionsVersesTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "mentions-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Mentioner",
      role: "contributor"
    )
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    @john_17 = BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    @john_18 = BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
  end

  test "saving a note with a plain verse reference auto-links and creates a mention" do
    note = Note.create!(
      title: "Love",
      user: @user,
      status: "published",
      content: "See John 3:16"
    )

    html = note.content.body.to_html
    assert_includes html, '<a href="/bible_verses/John/3/16">John 3:16</a>'
    assert_equal [@john_16.id], note.verse_mentions.pluck(:bible_verse_id)
  end

  test "saving a note with a verse range creates mentions for every verse" do
    note = Note.create!(
      title: "Range",
      user: @user,
      status: "published",
      content: "Read John 3:16-18"
    )

    html = note.content.body.to_html
    assert_includes html, '<a href="/bible_verses/John/3/16">John 3:16-18</a>'
    assert_equal [@john_16.id, @john_17.id, @john_18.id].sort, note.verse_mentions.pluck(:bible_verse_id).sort
  end

  test "re-saving an already linked note does not double-wrap" do
    note = Note.create!(
      title: "Linked",
      user: @user,
      status: "published",
      content: "See John 3:16"
    )

    note.update!(content: note.content.body.to_html)
    html = note.reload.content.body.to_html

    assert_equal 1, html.scan(%r{<a\b[^>]*href="/bible_verses/John/3/16"}).size
    assert_equal 1, note.verse_mentions.count
  end

  test "removing a verse reference removes the mention" do
    note = Note.create!(
      title: "Temp",
      user: @user,
      status: "published",
      content: "See John 3:16"
    )
    assert_equal 1, note.verse_mentions.count

    note.update!(content: "No verses anymore")
    assert_equal 0, note.reload.verse_mentions.count
  end
end
