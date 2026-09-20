module Imports
  class CsvCrossReferencesImporter
    RowResult = Struct.new(
      :source_reference,
      :target_reference,
      :content,
      :success,
      :error,
      :skipped,
      keyword_init: true
    )
    Result = Struct.new(:imported_count, :failed_count, :skipped, :row_results, keyword_init: true)

    def self.call(user:, io_or_string:)
      new(user: user, io_or_string: io_or_string).call
    end

    def initialize(user:, io_or_string:)
      @user = user
      @io_or_string = io_or_string
    end

    def call
      parsed = CsvCrossReferencesParser.parse(@io_or_string)
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
      if row.source_reference.blank?
        return failure(row, "Source verse is required")
      end

      if row.target_reference.blank?
        return failure(row, "Target verse is required")
      end

      if row.content.blank?
        return failure(row, "Comment is required")
      end

      source = VerseReferenceResolver.call(row.source_reference, allow_range: false)
      if source.error
        return failure(row, "Source: #{source.error}")
      end

      target = VerseReferenceResolver.call(row.target_reference, allow_range: true)
      if target.error
        return failure(row, "Target: #{target.error}")
      end

      if source.verse.id == target.verse.id || (target.end_verse && source.verse.id == target.end_verse.id)
        return failure(row, "Source and target verses must be different")
      end

      existing = find_existing_cross_reference(source.verse, target.verse)
      if existing
        return import_comment_on(existing, row)
      end

      create_cross_reference_with_comment(
        row: row,
        source_verse: source.verse,
        target_verse: target.verse,
        target_end_verse: target.end_verse
      )
    end

    def import_comment_on(cross_reference, row)
      if duplicate_csv_comment?(cross_reference: cross_reference, content: row.content)
        return skipped_result(row)
      end

      comment = build_comment(cross_reference, row.content)
      if comment.save
        success(row)
      else
        failure(row, comment.errors.full_messages.to_sentence)
      end
    end

    def create_cross_reference_with_comment(row:, source_verse:, target_verse:, target_end_verse:)
      cross_reference = CrossReference.new(
        source_verse: source_verse,
        target_verse: target_verse,
        target_end_verse: target_end_verse,
        user: @user
      )
      error = nil

      CrossReference.transaction do
        unless cross_reference.save
          error = cross_reference.errors.full_messages.to_sentence
          raise ActiveRecord::Rollback
        end

        comment = build_comment(cross_reference, row.content)
        unless comment.save
          error = comment.errors.full_messages.to_sentence
          raise ActiveRecord::Rollback
        end
      end

      return failure(row, error) if error

      success(row)
    end

    def find_existing_cross_reference(source_verse, target_verse)
      CrossReference.find_by(
        "(source_verse_id = ? AND target_verse_id = ?) OR (source_verse_id = ? AND target_verse_id = ?)",
        source_verse.id, target_verse.id, target_verse.id, source_verse.id
      )
    end

    def build_comment(cross_reference, content)
      Comment.new(
        user: @user,
        commentable: cross_reference,
        import_source: Comment::IMPORT_SOURCE_CSV,
        content: plain_text_to_rich_html(content)
      )
    end

    def duplicate_csv_comment?(cross_reference:, content:)
      candidates = Comment.from_import(Comment::IMPORT_SOURCE_CSV)
                          .where(user: @user, commentable: cross_reference)
                          .includes(:rich_text_content)

      normalized = normalize_plain_text(content)
      candidates.any? { |comment| normalize_plain_text(comment.content.to_plain_text) == normalized }
    end

    def normalize_plain_text(text)
      text.to_s.gsub(/\r\n?/, "\n").strip
    end

    def skipped_result(row)
      RowResult.new(
        source_reference: row.source_reference,
        target_reference: row.target_reference,
        content: row.content,
        success: true,
        error: nil,
        skipped: true
      )
    end

    def success(row)
      RowResult.new(
        source_reference: row.source_reference,
        target_reference: row.target_reference,
        content: row.content,
        success: true,
        error: nil,
        skipped: false
      )
    end

    def failure(row, message)
      RowResult.new(
        source_reference: row.source_reference,
        target_reference: row.target_reference,
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
