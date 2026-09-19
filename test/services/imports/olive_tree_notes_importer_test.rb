require "test_helper"

class Imports::OliveTreeNotesImporterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "olive-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Olive Importer",
      role: "contributor"
    )
    @acts_24 = BibleVerse.create!(book: "Acts", chapter: 8, verse: 24, text: "Then answered Simon", testament: "NT")
    @acts_26 = BibleVerse.create!(book: "Acts", chapter: 8, verse: 26, text: "And the angel of the Lord", testament: "NT")
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    @john_18 = BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    BibleVerse.create!(book: "1 John", chapter: 5, verse: 7, text: "For there are three", testament: "NT")
    @csv_path = Rails.root.join("test/fixtures/files/olive_tree/notes_export.csv")
  end

  test "imports note rows as verse comments and skips highlights" do
    result = nil

    assert_difference -> { Comment.count }, 4 do
      result = Imports::OliveTreeNotesImporter.call(
        user: @user,
        io_or_string: File.read(@csv_path)
      )
    end

    assert_equal 4, result.imported_count
    assert_equal 0, result.failed_count
    assert_equal 1, result.skipped[:non_note]
    assert_equal 1, result.skipped[:empty_content]

    comment = Comment.find_by(commentable: @acts_24)
    assert_equal @user, comment.user
    assert_equal "Blah blah", comment.content.to_plain_text.strip

    ranged = Comment.find_by(commentable: @john_16)
    assert_equal @john_18, ranged.end_verse
    assert_equal "Covers three verses", ranged.content.to_plain_text.strip
  end

  test "records failure when verse is missing" do
    csv = <<~CSV
      category_name,type,highlighter_name,title,content,reference_start,reference_end,associated_product,date_created,last_modified,tags
      Annotations,Note,,Title,Orphan note,Jude:1:99,Jude:1:99,,,2026-01-01T00:00:00Z,2026-01-01T00:00:00Z,""
    CSV

    result = Imports::OliveTreeNotesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/Verse not found/, result.row_results.first.error)
  end

  test "preserves angle brackets in note text as plain content" do
    csv = <<~CSV
      category_name,type,highlighter_name,title,content,reference_start,reference_end,associated_product,date_created,last_modified,tags
      Annotations,Note,,Title,"N<MN XZ",Acts:8:24,Acts:8:24,,,2026-01-01T00:00:00Z,2026-01-01T00:00:00Z,""
    CSV

    result = Imports::OliveTreeNotesImporter.call(user: @user, io_or_string: csv)

    assert_equal 1, result.imported_count
    comment = Comment.find_by(commentable: @acts_24)
    assert_equal "N<MN XZ", comment.content.to_plain_text.strip
  end
end
