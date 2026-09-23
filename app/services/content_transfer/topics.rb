# frozen_string_literal: true

module ContentTransfer
  module Topics
    module Exporter
      def self.call
        Topic.includes(verse_topics: [:user, :bible_verse, :rich_text_explanation]).order(:id).map do |topic|
          {
            "id" => topic.id,
            "name" => topic.name,
            "verse_topics" => topic.verse_topics.sort_by(&:id).map do |verse_topic|
              {
                "id" => verse_topic.id,
                "author_email" => verse_topic.user&.email,
                "verse_reference" => verse_topic.bible_verse&.reference,
                "explanation_html" => Html.from_rich_text(verse_topic.explanation)
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
        name = record["name"].to_s.strip
        if name.blank?
          failed!(source_id, "Topic name is required")
          return
        end

        topic = Topic.find_by("LOWER(name) = ?", name.downcase)
        if topic
          skipped!(source_id, topic)
        else
          topic = Topic.new(name: name)
          unless topic.save
            failed!(source_id, topic.errors.full_messages.to_sentence)
            return
          end
          imported!(source_id, topic)
        end

        Array(record["verse_topics"]).each do |verse_record|
          import_verse_topic(topic, verse_record)
        end
      end

      def import_verse_topic(topic, record)
        source_id = record["id"]
        user, = resolve_author(record["author_email"])
        verse, error = find_verse(record["verse_reference"])
        return failed!(source_id, error) if error

        existing = VerseTopic.find_by(topic: topic, bible_verse: verse, user: user)
        if existing
          skipped!(source_id, existing)
          return
        end

        verse_topic = VerseTopic.new(topic: topic, bible_verse: verse, user: user)
        assign_html(verse_topic, :explanation, record["explanation_html"].to_s)

        if verse_topic.save
          imported!(source_id, verse_topic)
        else
          failed!(source_id, verse_topic.errors.full_messages.to_sentence)
        end
      end
    end
  end
end
