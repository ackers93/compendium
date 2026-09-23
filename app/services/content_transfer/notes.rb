# frozen_string_literal: true

module ContentTransfer
  module Notes
    module Exporter
      def self.call
        Note.includes(:user, :rich_text_content, :tags).order(:id).map do |note|
          {
            "id" => note.id,
            "author_email" => note.user&.email,
            "title" => note.title,
            "status" => note.status,
            "tags" => note.tag_list.to_a,
            "content_html" => Html.from_rich_text(note.content)
          }
        end
      end
    end

    class Importer < BaseImporter
      private

      def import_records
        records.each { |record| import_record(record) }
      end

      def import_record(record)
        source_id = record["id"]
        user, = resolve_author(record["author_email"])
        title = record["title"].to_s
        html = record["content_html"].to_s
        normalized = Html.plain_text(html)

        existing = Note.where(user: user, title: title).includes(:rich_text_content).find do |note|
          Html.plain_text(note.content.body&.to_html) == normalized
        end
        if existing
          skipped!(source_id, existing)
          return
        end

        note = Note.new(
          user: user,
          title: title,
          status: record["status"].presence || "published"
        )
        note.tag_list = Array(record["tags"])
        assign_html(note, :content, html)

        if note.save
          imported!(source_id, note)
        else
          failed!(source_id, note.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
