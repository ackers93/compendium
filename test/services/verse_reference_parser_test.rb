require "test_helper"

class VerseReferenceParserTest < ActiveSupport::TestCase
  test "parses spaced full-book references and ranges" do
    parsed = VerseReferenceParser.parse("Genesis 1:1")
    assert_equal "Genesis", parsed.book
    assert_equal 1, parsed.chapter
    assert_equal 1, parsed.start_verse
    assert_nil parsed.end_verse

    ranged = VerseReferenceParser.parse("John 3:16-18")
    assert_equal "John", ranged.book
    assert_equal 3, ranged.chapter
    assert_equal 16, ranged.start_verse
    assert_equal 18, ranged.end_verse
  end

  test "parses compact abbreviations" do
    parsed = VerseReferenceParser.parse("gen1:1")
    assert_equal "Genesis", parsed.book
    assert_equal 1, parsed.chapter
    assert_equal 1, parsed.start_verse
  end

  test "parses olive-tree style book colon chapter colon verse refs" do
    parsed = VerseReferenceParser.parse("1ki:16:31")
    assert_equal "1 Kings", parsed.book
    assert_equal 16, parsed.chapter
    assert_equal 31, parsed.start_verse
    assert_nil parsed.end_verse

    ranged = VerseReferenceParser.parse("1ki:21:8-13")
    assert_equal "1 Kings", ranged.book
    assert_equal 21, ranged.chapter
    assert_equal 8, ranged.start_verse
    assert_equal 13, ranged.end_verse

    numbered = VerseReferenceParser.parse("1 John:5:7")
    assert_equal "1 John", numbered.book
    assert_equal 5, numbered.chapter
    assert_equal 7, numbered.start_verse
  end

  test "parses pro as Proverbs" do
    parsed = VerseReferenceParser.parse("pro:22:28")
    assert_equal "Proverbs", parsed.book
    assert_equal 22, parsed.chapter
    assert_equal 28, parsed.start_verse
  end

  test "returns nil for blank or unparseable input" do
    assert_nil VerseReferenceParser.parse("")
    assert_nil VerseReferenceParser.parse("NotABook 1:1")
  end
end
