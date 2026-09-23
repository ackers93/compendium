# frozen_string_literal: true

module ContentTransfer
  module TopicItems
    ITEABLE_HINTS = {
      "Note" => "Import notes first",
      "BibleThread" => "Import threads first",
      "Chiasm" => "Import chiasms first",
      "Comment" => "Import comments first",
      "CrossReference" => "Import cross-references first"
    }.freeze

    module Exporter
      def self.call
        TopicItem.includes(:user, :topic, :itemable, :rich_text_note).order(:id).map do |item|
          {
            "id" => item.id,
            "author_email" => item.user&.email,
            "topic_name" => item.topic&.name,
            "itemable_type" => item.itemable_type,
            "itemable_id" => item.itemable_id,
            "note_html" => Html.from_rich_text(item.note)
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
        topic_name = record["topic_name"].to_s.strip
        if topic_name.blank?
          failed!(source_id, "Topic name is required")
          return
        end

        topic = Topic.find_by("LOWER(name) = ?", topic_name.downcase)
        unless topic
          failed!(source_id, "Import topics first (topic #{topic_name.inspect} was not found).")
          return
        end

        itemable, error = resolve_itemable(record)
        return failed!(source_id, error) if error

        existing = TopicItem.find_by(topic: topic, itemable: itemable, user: user)
        if existing
          skipped!(source_id, existing)
          return
        end

        item = TopicItem.new(topic: topic, itemable: itemable, user: user)
        assign_html(item, :note, record["note_html"].to_s)

        if item.save
          imported!(source_id, item)
        else
          failed!(source_id, item.errors.full_messages.to_sentence)
        end
      end

      def resolve_itemable(record)
        type = record["itemable_type"].to_s
        unless TopicItem::ITEMABLE_TYPES.include?(type)
          return [nil, "Unknown pin type #{type.inspect}"]
        end

        klass = type.constantize
        itemable = id_map.find_record(klass, record["itemable_id"])
        unless itemable
          hint = ITEABLE_HINTS[type] || "Import #{type.underscore.pluralize.tr('_', ' ')} first"
          return [nil, "#{hint} (no mapping for #{type} #{record["itemable_id"]})."]
        end

        [itemable, nil]
      end
    end
  end
end
