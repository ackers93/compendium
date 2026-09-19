require "test_helper"

class Imports::OliveTreeNotesParserTest < ActiveSupport::TestCase
  setup do
    @csv_path = Rails.root.join("test/fixtures/files/olive_tree/notes_export.csv")
  end

  test "keeps only notes with content and reference" do
    result = Imports::OliveTreeNotesParser.parse(File.read(@csv_path))

    assert_equal 4, result.rows.size
    assert_equal 1, result.skipped[:non_note]
    assert_equal 1, result.skipped[:empty_content]

    references = result.rows.map(&:reference)
    assert_includes references, "Acts 8:24"
    assert_includes references, "Acts 8:26"
    assert_includes references, "John 3:16-18"
    assert_includes references, "1 John 5:7"
  end

  test "normalizes olive tree book colon chapter colon verse refs" do
    csv = <<~CSV
      category_name,type,highlighter_name,title,content,reference_start,reference_end,associated_product,date_created,last_modified,tags
      Annotations,Note,,Title,Hello,1 John:5:7,1 John:5:7,,,2026-01-01T00:00:00Z,2026-01-01T00:00:00Z,""
    CSV

    result = Imports::OliveTreeNotesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "1 John 5:7", result.rows.first.reference
    assert_equal "Hello", result.rows.first.content
  end

  test "strips utf-8 bom from export files" do
    csv = "\uFEFFcategory_name,type,highlighter_name,title,content,reference_start,reference_end,associated_product,date_created,last_modified,tags\n" \
          "Annotations,Note,,Title,Body,Acts:8:24,Acts:8:24,,,2026-01-01T00:00:00Z,2026-01-01T00:00:00Z,\"\"\n"

    result = Imports::OliveTreeNotesParser.parse(csv)

    assert_equal 1, result.rows.size
    assert_equal "Acts 8:24", result.rows.first.reference
  end

  test "accepts binary-encoded uploaded file content" do
    csv = (+"\xEF\xBB\xBFcategory_name,type,highlighter_name,title,content,reference_start,reference_end,associated_product,date_created,last_modified,tags\n" \
           "Annotations,Note,,Title,Body,Acts:8:24,Acts:8:24,,,2026-01-01T00:00:00Z,2026-01-01T00:00:00Z,\"\"\n")
          .force_encoding(Encoding::ASCII_8BIT)

    result = Imports::OliveTreeNotesParser.parse(StringIO.new(csv))

    assert_equal 1, result.rows.size
    assert_equal "Acts 8:24", result.rows.first.reference
  end
end
