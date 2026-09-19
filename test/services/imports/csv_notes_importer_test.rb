require "test_helper"

class Imports::CsvNotesImporterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "csv-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "CSV Importer",
      role: "contributor"
    )
    @genesis = BibleVerse.create!(book: "Genesis", chapter: 1, verse: 1, text: "In the beginning", testament: "OT")
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    @john_18 = BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    @acts_24 = BibleVerse.create!(book: "Acts", chapter: 8, verse: 24, text: "Then answered Simon", testament: "NT")
    @csv_path = Rails.root.join("test/fixtures/files/csv_import/notes.csv")
  end

  test "imports comments from csv with headers" do
    result = nil

    assert_difference -> { Comment.count }, 3 do
      result = Imports::CsvNotesImporter.call(
        user: @user,
        io_or_string: File.read(@csv_path)
      )
    end

    assert_equal 3, result.imported_count
    assert_equal 0, result.failed_count

    comment = Comment.find_by(commentable: @genesis)
    assert_equal @user, comment.user
    assert_equal Comment::IMPORT_SOURCE_CSV, comment.import_source
    assert_equal "In the beginning God created", comment.content.to_plain_text.strip

    ranged = Comment.find_by(commentable: @john_16)
    assert_equal @john_18, ranged.end_verse
    assert_equal "For God so loved the world, that he gave", ranged.content.to_plain_text.strip
  end

  test "records failure when verse is missing" do
    csv = <<~CSV
      verse,comment
      Jude 1:99,Orphan note
    CSV

    result = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/Verse not found/, result.row_results.first.error)
  end

  test "records failure when a row is missing a comment" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,
    CSV

    result = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/Comment is required/, result.row_results.first.error)
  end

  test "preserves angle brackets in comment text" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,"N<MN XZ"
    CSV

    result = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)

    assert_equal 1, result.imported_count
    comment = Comment.find_by(commentable: @genesis)
    assert_equal "N<MN XZ", comment.content.to_plain_text.strip
  end

  test "skips duplicates of prior csv imports only" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,Imported note
    CSV

    first = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)
    assert_equal 1, first.imported_count

    Comment.create!(
      user: @user,
      commentable: @genesis,
      content: "Imported note"
    )

    assert_no_difference -> { Comment.count } do
      second = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)
      assert_equal 0, second.imported_count
      assert_equal 1, second.skipped[:duplicate]
    end

    assert_equal 1, Comment.from_import(Comment::IMPORT_SOURCE_CSV).where(commentable: @genesis).count
    assert_equal 1, Comment.where(commentable: @genesis, import_source: nil).count
  end

  test "imports when matching text exists only as a hand-written comment" do
    Comment.create!(
      user: @user,
      commentable: @genesis,
      content: "Same words"
    )

    csv = <<~CSV
      verse,comment
      Genesis 1:1,Same words
    CSV

    assert_difference -> { Comment.count }, 1 do
      result = Imports::CsvNotesImporter.call(user: @user, io_or_string: csv)
      assert_equal 1, result.imported_count
      assert_equal 0, result.skipped[:duplicate].to_i
    end
  end
end
