require "test_helper"

class Imports::CsvNotesParserTest < ActiveSupport::TestCase
  test "reads verse and comment headers" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,In the beginning
      John 3:16-18,For God so loved
    CSV

    result = Imports::CsvNotesParser.parse(csv)

    assert_equal 2, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.reference
    assert_equal "In the beginning", result.rows.first.content
    assert_equal "John 3:16-18", result.rows.last.reference
  end

  test "accepts reference and content aliases" do
    csv = <<~CSV
      reference,content
      Acts 8:24,Then answered Simon
    CSV

    result = Imports::CsvNotesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Acts 8:24", result.rows.first.reference
    assert_equal "Then answered Simon", result.rows.first.content
  end

  test "treats the first row as data when headers are missing" do
    csv = <<~CSV
      Genesis 1:1,In the beginning
      John 3:16,For God so loved
    CSV

    result = Imports::CsvNotesParser.parse(csv)

    assert_equal 2, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.reference
    assert_equal "In the beginning", result.rows.first.content
  end

  test "skips blank rows and keeps incomplete rows for the importer" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,In the beginning

      John 3:16,
      ,Missing verse
    CSV

    result = Imports::CsvNotesParser.parse(csv)

    assert_equal 3, result.rows.size
    assert_equal "John 3:16", result.rows[1].reference
    assert_equal "", result.rows[1].content
    assert_equal "", result.rows[2].reference
    assert_equal "Missing verse", result.rows[2].content
  end

  test "strips utf-8 bom from uploaded files" do
    csv = "\uFEFFverse,comment\nGenesis 1:1,In the beginning\n"

    result = Imports::CsvNotesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.reference
  end
end
