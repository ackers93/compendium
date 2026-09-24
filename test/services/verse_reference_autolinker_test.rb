# frozen_string_literal: true

require "test_helper"

class VerseReferenceAutolinkerTest < ActiveSupport::TestCase
  setup do
    BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    BibleVerse.create!(book: "Genesis", chapter: 1, verse: 1, text: "In the beginning", testament: "OT")
  end

  test "wraps plain references in links" do
    html = "<div>See John 3:16 today.</div>"
    result = VerseReferenceAutolinker.call(html)

    assert_includes result, '<a href="/bible_verses/John/3/16">John 3:16</a>'
    assert_includes result, "See "
    assert_includes result, " today."
  end

  test "leaves existing anchors alone" do
    html = %(<div>See <a href="/bible_verses/John/3/16">John 3:16</a> again.</div>)
    result = VerseReferenceAutolinker.call(html)

    assert_equal html, result
  end

  test "skips references inside code tags" do
    html = "<div><code>John 3:16</code> and Genesis 1:1</div>"
    result = VerseReferenceAutolinker.call(html)

    assert_includes result, "<code>John 3:16</code>"
    assert_includes result, '<a href="/bible_verses/Genesis/1/1">Genesis 1:1</a>'
  end

  test "links ranges to the start verse and keeps display text" do
    html = "<div>Read John 3:16-18</div>"
    result = VerseReferenceAutolinker.call(html)

    assert_includes result, '<a href="/bible_verses/John/3/16">John 3:16-18</a>'
  end

  test "returns unchanged html when nothing matches" do
    html = "<div>No verses here.</div>"
    assert_equal html, VerseReferenceAutolinker.call(html)
  end

  test "returns blank input unchanged" do
    assert_equal "", VerseReferenceAutolinker.call("")
  end
end
