# frozen_string_literal: true

require "test_helper"

class VerseReferenceScannerTest < ActiveSupport::TestCase
  setup do
    BibleVerse.create!(book: "Genesis", chapter: 1, verse: 1, text: "In the beginning", testament: "OT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    BibleVerse.create!(book: "Isaiah", chapter: 40, verse: 1, text: "Comfort ye", testament: "OT")
    BibleVerse.create!(book: "1 Kings", chapter: 16, verse: 31, text: "And it came to pass", testament: "OT")
    BibleVerse.create!(book: "1 John", chapter: 5, verse: 7, text: "For there are three", testament: "NT")
  end

  test "finds full-book references with offsets" do
    text = "See Genesis 1:1 for the start."
    matches = VerseReferenceScanner.scan(text)

    assert_equal 1, matches.size
    match = matches.first
    assert_equal "Genesis 1:1", match.text
    assert_equal 4, match.start_offset
    assert_equal 15, match.end_offset
    assert_equal "Genesis", match.parsed.book
    assert_equal 1, match.parsed.chapter
    assert_equal 1, match.parsed.start_verse
    assert_equal "Genesis", match.verse.book
  end

  test "finds abbreviations and ranges" do
    text = "Compare gen1:1 with John 3:16-18"
    matches = VerseReferenceScanner.scan(text)

    assert_equal 2, matches.size
    assert_equal "Genesis", matches[0].parsed.book
    assert_equal "John", matches[1].parsed.book
    assert_equal 16, matches[1].parsed.start_verse
    assert_equal 18, matches[1].parsed.end_verse
    assert_equal 18, matches[1].end_verse.verse
  end

  test "finds numbered books and olive-tree style refs" do
    text = "Notes on 1ki:16:31 and 1 John 5:7"
    matches = VerseReferenceScanner.scan(text)

    assert_equal 2, matches.size
    assert_equal "1 Kings", matches[0].parsed.book
    assert_equal "1 John", matches[1].parsed.book
  end

  test "rejects lowercase short abbreviations without period" do
    text = "This is 1:1 not a verse, but Is 40:1 is."
    matches = VerseReferenceScanner.scan(text)

    assert_equal 1, matches.size
    assert_equal "Is 40:1", matches.first.text
    assert_equal "Isaiah", matches.first.parsed.book
  end

  test "accepts short abbreviations with period" do
    text = "See Is. 40:1"
    matches = VerseReferenceScanner.scan(text)

    assert_equal 1, matches.size
    assert_equal "Isaiah", matches.first.parsed.book
  end

  test "skips references that do not exist in the database" do
    text = "John 99:99 is not real"
    matches = VerseReferenceScanner.scan(text)

    assert_empty matches
  end

  test "can scan without resolving against the database" do
    text = "John 99:99"
    matches = VerseReferenceScanner.scan(text, resolve: false)

    assert_equal 1, matches.size
    assert_nil matches.first.verse
    assert_equal "John", matches.first.parsed.book
  end
end
