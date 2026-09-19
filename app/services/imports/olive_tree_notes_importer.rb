module Imports
  class OliveTreeNotesImporter
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
      parsed = OliveTreeNotesParser.parse(@io_or_string)
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
      parsed = VerseReferenceParser.parse(row.reference)
      unless parsed
        return failure(row, "Could not parse \"#{row.reference}\".")
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

      if duplicate_olive_tree_comment?(verse: verse, end_verse: end_verse, content: row.content)
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
        import_source: Comment::IMPORT_SOURCE_OLIVE_TREE,
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

    def duplicate_olive_tree_comment?(verse:, end_verse:, content:)
      candidates = Comment.from_import(Comment::IMPORT_SOURCE_OLIVE_TREE)
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
