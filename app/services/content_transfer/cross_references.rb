# frozen_string_literal: true

module ContentTransfer
  module CrossReferences
    module Exporter
      def self.call
        CrossReference.includes(:user, :source_verse, :target_verse, :target_end_verse).order(:id).map do |xref|
          {
            "id" => xref.id,
            "author_email" => xref.user&.email,
            "source_reference" => xref.source_verse&.reference,
            "target_reference" => xref.target_verse&.reference,
            "target_end_reference" => xref.target_end_verse&.reference
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

        source_verse, source_error = find_verse(record["source_reference"])
        return failed!(source_id, "Source: #{source_error}") if source_error

        target_verse, target_error = find_verse(record["target_reference"])
        return failed!(source_id, "Target: #{target_error}") if target_error

        target_end = nil
        if record["target_end_reference"].present?
          target_end, end_error = find_verse(record["target_end_reference"])
          return failed!(source_id, "Target end: #{end_error}") if end_error
        end

        existing = find_existing(source_verse, target_verse)
        if existing
          skipped!(source_id, existing)
          return
        end

        xref = CrossReference.new(
          user: user,
          source_verse: source_verse,
          target_verse: target_verse,
          target_end_verse: target_end
        )

        if xref.save
          imported!(source_id, xref)
        else
          failed!(source_id, xref.errors.full_messages.to_sentence)
        end
      end

      def find_existing(source_verse, target_verse)
        CrossReference.find_by(
          "(source_verse_id = ? AND target_verse_id = ?) OR (source_verse_id = ? AND target_verse_id = ?)",
          source_verse.id, target_verse.id, target_verse.id, source_verse.id
        )
      end
    end
  end
end
