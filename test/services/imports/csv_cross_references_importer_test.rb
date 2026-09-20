require "test_helper"

class Imports::CsvCrossReferencesImporterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "csv-xref-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "CSV Xref Importer",
      role: "contributor"
    )
    @genesis = BibleVerse.create!(book: "Genesis", chapter: 1, verse: 1, text: "In the beginning", testament: "OT")
    @john_16 = BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    @john_18 = BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    @acts_24 = BibleVerse.create!(book: "Acts", chapter: 8, verse: 24, text: "Then answered Simon", testament: "NT")
    @csv_path = Rails.root.join("test/fixtures/files/csv_import/cross_references.csv")
  end

  test "imports compact abbreviations with a comment" do
    kings_31 = BibleVerse.create!(book: "1 Kings", chapter: 16, verse: 31, text: "And it came to pass", testament: "OT")
    proverbs = BibleVerse.create!(book: "Proverbs", chapter: 22, verse: 28, text: "Remove not the ancient landmark", testament: "OT")

    csv = <<~CSV
      source,target,comment
      1ki:16:31,pro:22:28,"Jezebel, the Sidonian princess who became queen of Israel."
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 1, result.imported_count
    assert_equal 0, result.failed_count

    xref = CrossReference.find_by(source_verse: kings_31, target_verse: proverbs)
    assert_equal @user, xref.user
    comment = xref.comments.find_by(user: @user)
    assert_match(/Sidonian princess/, comment.content.to_plain_text)
    assert_equal Comment::IMPORT_SOURCE_CSV, comment.import_source
  end

  test "imports cross-references from csv with headers" do
    result = nil

    assert_difference -> { CrossReference.count }, 2 do
      assert_difference -> { Comment.count }, 3 do
        result = Imports::CsvCrossReferencesImporter.call(
          user: @user,
          io_or_string: File.read(@csv_path)
        )
      end
    end

    assert_equal 3, result.imported_count
    assert_equal 0, result.failed_count

    first = CrossReference.find_by(source_verse: @genesis, target_verse: @john_16)
    assert_nil first.target_end_verse
    texts = first.comments.map { |comment| comment.content.to_plain_text.strip }
    assert_includes texts, "The Word was in the beginning"
    assert_includes texts, "For God so loved the world, that he gave"

    acts = CrossReference.find_by(source_verse: @acts_24, target_verse: @john_16)
    assert_equal "Then answered Simon", acts.comments.first.content.to_plain_text.strip
  end

  test "imports a target range onto a new cross-reference" do
    csv = <<~CSV
      source,target,comment
      Acts 8:24,John 3:16-18,Loved the world
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 1, result.imported_count
    xref = CrossReference.find_by(source_verse: @acts_24, target_verse: @john_16)
    assert_equal @john_18, xref.target_end_verse
  end

  test "records failure when a verse is missing" do
    csv = <<~CSV
      source,target,comment
      Jude 1:99,Genesis 1:1,Orphan xref
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/Verse not found/, result.row_results.first.error)
  end

  test "records failure when source is a range" do
    csv = <<~CSV
      source,target,comment
      John 3:16-18,Genesis 1:1,Source must be a single verse
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/single verse/, result.row_results.first.error)
  end

  test "records failure when a row is missing a comment" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/Comment is required/, result.row_results.first.error)
    assert_equal 0, CrossReference.count
  end

  test "records failure when source and target are the same verse" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,Genesis 1:1,Same verse
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 0, result.imported_count
    assert_equal 1, result.failed_count
    assert_match(/must be different/, result.row_results.first.error)
  end

  test "preserves angle brackets in comment text" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,"N<MN XZ"
    CSV

    result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)

    assert_equal 1, result.imported_count
    comment = CrossReference.find_by(source_verse: @genesis).comments.first
    assert_equal "N<MN XZ", comment.content.to_plain_text.strip
  end

  test "adds a comment to an existing pair in either direction" do
    CrossReference.create!(user: @user, source_verse: @john_16, target_verse: @genesis)

    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,Added onto existing
    CSV

    assert_no_difference -> { CrossReference.count } do
      result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)
      assert_equal 1, result.imported_count
    end

    xref = CrossReference.find_by(source_verse: @john_16, target_verse: @genesis)
    assert_equal "Added onto existing", xref.comments.first.content.to_plain_text.strip
    assert_equal Comment::IMPORT_SOURCE_CSV, xref.comments.first.import_source
  end

  test "skips duplicates of prior csv imports only" do
    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,Imported xref
    CSV

    first = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)
    assert_equal 1, first.imported_count

    xref = CrossReference.find_by(source_verse: @genesis, target_verse: @john_16)
    Comment.create!(
      user: @user,
      commentable: xref,
      content: "Imported xref"
    )

    assert_no_difference -> { Comment.count } do
      second = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)
      assert_equal 0, second.imported_count
      assert_equal 1, second.skipped[:duplicate]
    end

    assert_equal 1, Comment.from_import(Comment::IMPORT_SOURCE_CSV).where(commentable: xref).count
    assert_equal 1, Comment.where(commentable: xref, import_source: nil).count
  end

  test "imports when matching text exists only as a hand-written comment" do
    xref = CrossReference.create!(user: @user, source_verse: @genesis, target_verse: @john_16)
    Comment.create!(
      user: @user,
      commentable: xref,
      content: "Same words"
    )

    csv = <<~CSV
      source,target,comment
      Genesis 1:1,John 3:16,Same words
    CSV

    assert_difference -> { Comment.count }, 1 do
      result = Imports::CsvCrossReferencesImporter.call(user: @user, io_or_string: csv)
      assert_equal 1, result.imported_count
      assert_equal 0, result.skipped[:duplicate].to_i
    end
  end
end
