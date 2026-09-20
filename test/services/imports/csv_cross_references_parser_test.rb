require "test_helper"

class Imports::CsvCrossReferencesParserTest < ActiveSupport::TestCase
  test "reads source, target, and comment headers" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,The Word was in the beginning
      Genesis 1:1,John 3:16-18,For God so loved
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 2, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.source_reference
    assert_equal "John 3:16", result.rows.first.target_reference
    assert_equal "The Word was in the beginning", result.rows.first.content
    assert_equal "John 3:16-18", result.rows.last.target_reference
  end

  test "accepts verse1, verse2, and content aliases" do
    csv = <<~CSV
      verse1,verse2,content
      Acts 8:24,John 3:16,Then answered Simon
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Acts 8:24", result.rows.first.source_reference
    assert_equal "John 3:16", result.rows.first.target_reference
    assert_equal "Then answered Simon", result.rows.first.content
  end

  test "treats two verse columns as source and target" do
    csv = <<~CSV
      verse,verse,comment
      Genesis 1:1,John 3:16,The Word was in the beginning
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.source_reference
    assert_equal "John 3:16", result.rows.first.target_reference
  end

  test "accepts from, to, point headers and multiline quoted comments" do
    csv = <<~CSV
      from,to,point
      1ki:16:31,pro:22:28,"Jezebel, the Sidonian princess who became queen of Israel.
      Influence is powerful for good or harm."
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "1ki:16:31", result.rows.first.source_reference
    assert_equal "pro:22:28", result.rows.first.target_reference
    assert_match(/Sidonian princess/, result.rows.first.content)
    assert_match(/national worship|Influence is powerful/, result.rows.first.content)
  end

  test "treats an unknown third-column header as content" do
    csv = <<~CSV
      source,target,observation
      Genesis 1:1,John 3:16,The Word was in the beginning
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "The Word was in the beginning", result.rows.first.content
  end

  test "normalizes typographic double quotes so pasted csv can parse" do
    csv = %(source,target,comment\nGenesis 1:1,John 3:16,\u201CThe Word was in the beginning\u201D\n)

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.source_reference
    assert_equal "The Word was in the beginning", result.rows.first.content
  end

  test "treats the first row as data when headers are missing" do
    csv = <<~CSV
      Genesis 1:1,John 3:16,The Word was in the beginning
      Acts 8:24,John 3:16,Then answered Simon
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 2, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.source_reference
    assert_equal "John 3:16", result.rows.first.target_reference
    assert_equal "The Word was in the beginning", result.rows.first.content
  end

  test "skips blank rows and keeps incomplete rows for the importer" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,The Word

      Genesis 1:1,,
      ,John 3:16,Missing source
    CSV

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 3, result.rows.size
    assert_equal "Genesis 1:1", result.rows[1].source_reference
    assert_equal "", result.rows[1].target_reference
    assert_equal "", result.rows[2].source_reference
    assert_equal "Missing source", result.rows[2].content
  end

  test "strips utf-8 bom from uploaded files" do
    csv = "\uFEFFsource,target,comment\nGenesis 1:1,John 3:16,The Word\n"

    result = Imports::CsvCrossReferencesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Genesis 1:1", result.rows.first.source_reference
  end
end
