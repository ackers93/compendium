# frozen_string_literal: true

module ContentTransfer
  FORMAT = "compendium.export"
  VERSION = 1

  Type = Struct.new(:key, :label, :icon, :exporter, :importer, :counter, keyword_init: true)

  module_function

  def types
    @types ||= [
      Type.new(key: "content_tables", label: "Content tables", icon: "fa-table", exporter: ContentTables::Exporter, importer: ContentTables::Importer, counter: -> { ContentTable.count }),
      Type.new(key: "notes", label: "Notes", icon: "fa-note-sticky", exporter: Notes::Exporter, importer: Notes::Importer, counter: -> { Note.count }),
      Type.new(key: "cross_references", label: "Cross-references", icon: "fa-link", exporter: CrossReferences::Exporter, importer: CrossReferences::Importer, counter: -> { CrossReference.count }),
      Type.new(key: "comments", label: "Comments", icon: "fa-comment", exporter: Comments::Exporter, importer: Comments::Importer, counter: -> { Comment.count }),
      Type.new(key: "topics", label: "Topics", icon: "fa-bookmark", exporter: Topics::Exporter, importer: Topics::Importer, counter: -> { Topic.count }),
      Type.new(key: "threads", label: "Threads", icon: "fa-route", exporter: Threads::Exporter, importer: Threads::Importer, counter: -> { BibleThread.count }),
      Type.new(key: "chiasms", label: "Chiasms", icon: "fa-grip-lines", exporter: Chiasms::Exporter, importer: Chiasms::Importer, counter: -> { Chiasm.count }),
      Type.new(key: "topic_items", label: "Topic pins", icon: "fa-thumbtack", exporter: TopicItems::Exporter, importer: TopicItems::Importer, counter: -> { TopicItem.count })
    ].freeze
  end

  def type_keys
    types.map(&:key)
  end

  def find_type(key)
    types.find { |type| type.key == key.to_s }
  end

  def find_type!(key)
    find_type(key) || raise(Envelope::Invalid, "Unknown export type #{key.inspect}")
  end

  def export(type_key, source:)
    type = find_type!(type_key)
    Envelope.build(type: type.key, source: source, records: type.exporter.call)
  end

  def export_zip(source:)
    files = types.each_with_object({}) do |type, hash|
      hash["compendium-#{type.key}.json"] = export(type.key, source: source)
    end
    ZipBuilder.build(files)
  end

  def import(json, type:, admin:)
    envelope = Envelope.parse(json)
    expected = find_type!(type)
    if envelope.type != expected.key
      raise Envelope::Invalid, "This file is a #{envelope.type} export. Choose the #{envelope.type} import, or upload a #{expected.key} file."
    end

    NotificationDispatcher.silence do
      expected.importer.call(envelope, admin: admin)
    end
  end
end
