# frozen_string_literal: true

module ContentTransfer
  module Comments
    COMMENTABLE_IMPORT_HINTS = {
      "Note" => "Import notes first",
      "CrossReference" => "Import cross-references first"
    }.freeze

    module Exporter
      def self.call
        Comment.includes(:user, :end_verse, :rich_text_content, :commentable).order(:id).map do |comment|
          payload = {
            "id" => comment.id,
            "parent_id" => comment.parent_id,
            "author_email" => comment.user&.email,
            "commentable_type" => comment.commentable_type,
            "commentable_id" => comment.commentable_id,
            "coverage" => comment.coverage,
            "import_source" => comment.import_source,
            "content_html" => Html.from_rich_text(comment.content)
          }

          if comment.commentable.is_a?(BibleVerse)
            payload["start_reference"] = comment.commentable.reference
            payload["end_reference"] = comment.end_verse&.reference
          end

          payload
        end
      end
    end

    class Importer < BaseImporter
      private

      def import_records
        pending = records.dup

        while pending.any?
          next_pending = []

          pending.each do |record|
            parent_id = record["parent_id"]
            if parent_id.present? && id_map.lookup("Comment", parent_id).nil?
              next_pending << record
              next
            end

            import_record(record)
          end

          break if next_pending.size == pending.size

          pending = next_pending
        end

        pending.each do |record|
          failed!(record["id"], "Parent comment was not imported. Import comments (including replies' parents) first.")
        end
      end

      def import_record(record)
        source_id = record["id"]
        user, = resolve_author(record["author_email"])
        html = record["content_html"].to_s
        coverage = record["coverage"].presence || Comment::COVERAGE_VERSE

        commentable, end_verse, error = resolve_commentable(record)
        return failed!(source_id, error) if error

        parent = nil
        if record["parent_id"].present?
          parent = id_map.find_record(Comment, record["parent_id"])
          return failed!(source_id, "Parent comment was not imported. Import comments (including replies' parents) first.") unless parent
        end

        normalized = Html.plain_text(html)
        existing = Comment.where(
          user: user,
          commentable: commentable,
          parent: parent,
          end_verse: end_verse,
          coverage: coverage
        ).includes(:rich_text_content).find do |comment|
          Html.plain_text(comment.content.body&.to_html) == normalized
        end
        if existing
          skipped!(source_id, existing)
          return
        end

        comment = Comment.new(
          user: user,
          commentable: commentable,
          parent: parent,
          end_verse: end_verse,
          coverage: coverage,
          import_source: record["import_source"].presence
        )
        assign_html(comment, :content, html)

        if comment.save
          imported!(source_id, comment)
        else
          failed!(source_id, comment.errors.full_messages.to_sentence)
        end
      end

      def resolve_commentable(record)
        type = record["commentable_type"].to_s

        case type
        when "BibleVerse"
          verse, error = find_verse(record["start_reference"])
          return [nil, nil, error] if error

          end_verse = nil
          if record["end_reference"].present?
            end_verse, end_error = find_verse(record["end_reference"])
            return [nil, nil, end_error] if end_error
          end

          [verse, end_verse, nil]
        when "Note", "CrossReference"
          klass = type.constantize
          record_obj = id_map.find_record(klass, record["commentable_id"])
          unless record_obj
            hint = COMMENTABLE_IMPORT_HINTS[type]
            return [nil, nil, "#{hint} (no mapping for #{type} #{record["commentable_id"]})."]
          end

          [record_obj, nil, nil]
        else
          [nil, nil, "Unknown commentable type #{type.inspect}"]
        end
      end
    end
  end
end
