module Imports
  class CsvNotesImporter
    RowResult = Struct.new(:reference, :content, :success, :error, :skipped, keyword_init: true)
    Result = Struct.new(:imported_count, :failed_count, :skipped, :row_results, keyword_init: true)

    def self.call(user:, io_or_string:)
      new(user: user, io_or_string: io_or_string).call
    end

    def initialize(user:, io_or_string:)
      @user = user
      @io_or_string = io_or_string
    end

    def call
      parsed = CsvNotesParser.parse(@io_or_string)
      row_results = []
      imported_count = 0
      failed_count = 0
      skipped = parsed.skipped.dup

      parsed.rows.each do |row|
        outcome = import_row(row)
        row_results << outcome
        if outcome.skipped
          skipped[:duplicate] += 1
        elsif outcome.success
          imported_count += 1
        else
          failed_count += 1
        end
      end

      Result.new(
        imported_count: imported_count,
        failed_count: failed_count,
        skipped: skipped,
        row_results: row_results
      )
    end

    private

    def import_row(row)
      if row.reference.blank?
        return failure(row, "Verse reference is required")
      end

      if row.content.blank?
        return failure(row, "Comment is required")
      end

      parsed = VerseReferenceParser.parse(row.reference)
      unless parsed
        return failure(row, "Could not parse \"#{row.reference}\". Try formats like gen1:1, Gen 1:1, or Genesis 1:1-4.")
      end

      verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.start_verse)
      unless verse
        return failure(row, "Verse not found: #{parsed.display}")
      end

      end_verse = nil
      if parsed.end_verse
        end_verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.end_verse)
        unless end_verse
          return failure(row, "End verse not found: #{parsed.book} #{parsed.chapter}:#{parsed.end_verse}")
        end
      end

      if duplicate_csv_comment?(verse: verse, end_verse: end_verse, content: row.content)
        return RowResult.new(
          reference: row.reference,
          content: row.content,
          success: true,
          error: nil,
          skipped: true
        )
      end

      comment = Comment.new(
        user: @user,
        commentable: verse,
        end_verse: end_verse,
        import_source: Comment::IMPORT_SOURCE_CSV,
        content: plain_text_to_rich_html(row.content)
      )

      if comment.save
        RowResult.new(
          reference: comment.verse_reference,
          content: row.content,
          success: true,
          error: nil,
          skipped: false
        )
      else
        failure(row, comment.errors.full_messages.to_sentence)
      end
    end

    def duplicate_csv_comment?(verse:, end_verse:, content:)
      candidates = Comment.from_import(Comment::IMPORT_SOURCE_CSV)
                          .where(
                            user: @user,
                            commentable: verse,
                            end_verse_id: end_verse&.id
                          )
                          .includes(:rich_text_content)

      normalized = normalize_plain_text(content)
      candidates.any? { |comment| normalize_plain_text(comment.content.to_plain_text) == normalized }
    end

    def normalize_plain_text(text)
      text.to_s.gsub(/\r\n?/, "\n").strip
    end

    def failure(row, message)
      RowResult.new(
        reference: row.reference,
        content: row.content,
        success: false,
        error: message,
        skipped: false
      )
    end

    def plain_text_to_rich_html(text)
      escaped = ERB::Util.html_escape(text.to_s)
      escaped.split(/\r?\n/).map { |line| "<div>#{line.presence || '<br>'}</div>" }.join
    end
  end
end
