# frozen_string_literal: true

module ContentTransfer
  module Threads
    module Exporter
      def self.call
        BibleThread.includes(:user, bible_thread_entries: [:user, :bible_verse]).order(:id).map do |thread|
          {
            "id" => thread.id,
            "author_email" => thread.user&.email,
            "title" => thread.title,
            "entries" => thread.bible_thread_entries.sort_by { |entry| entry.position.to_i }.map do |entry|
              {
                "id" => entry.id,
                "author_email" => entry.user&.email,
                "position" => entry.position,
                "verse_reference" => entry.bible_verse&.reference,
                "comment" => entry.comment
              }
            end
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
        entries = Array(record["entries"])
        verse_refs = entries.map { |entry| entry["verse_reference"].to_s }

        existing = BibleThread.where(user: user, title: title).includes(bible_thread_entries: :bible_verse).find do |thread|
          thread.bible_thread_entries.sort_by { |entry| entry.position.to_i }.map { |entry| entry.bible_verse&.reference } == verse_refs
        end
        if existing
          skipped!(source_id, existing)
          existing.bible_thread_entries.each do |entry|
            source_entry = entries.find { |row| row["verse_reference"].to_s == entry.bible_verse&.reference && row["position"].to_i == entry.position.to_i }
            remember("BibleThreadEntry", source_entry["id"], entry.id) if source_entry
          end
          return
        end

        thread = BibleThread.new(user: user, title: title, current_editor: user)

        entries.each do |entry_record|
          verse, error = find_verse(entry_record["verse_reference"])
          return failed!(source_id, error) if error

          entry_user, = resolve_author(entry_record["author_email"])
          thread.bible_thread_entries.build(
            bible_verse: verse,
            position: entry_record["position"],
            comment: entry_record["comment"],
            user: entry_user
          )
        end

        if thread.save
          imported!(source_id, thread)
          sorted_source = entries.sort_by { |entry_record| entry_record["position"].to_i }
          sorted_saved = thread.bible_thread_entries.sort_by { |entry| entry.position.to_i }
          sorted_source.zip(sorted_saved).each do |entry_record, entry|
            remember("BibleThreadEntry", entry_record["id"], entry.id) if entry_record && entry
          end
        else
          failed!(source_id, thread.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
