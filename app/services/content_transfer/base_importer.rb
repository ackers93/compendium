# frozen_string_literal: true

module ContentTransfer
  class BaseImporter
    def self.call(envelope, admin:)
      new(envelope, admin: admin).call
    end

    def initialize(envelope, admin:)
      @envelope = envelope
      @admin = admin
      @authors = AuthorResolver.new(admin: admin)
      @id_map = IdMap.new(source: envelope.source)
      @imported = 0
      @skipped = 0
      @failed = 0
      @errors = []
    end

    def call
      import_records
      Result.new(
        imported_count: @imported,
        skipped_count: @skipped,
        failed_count: @failed,
        missing_authors: @authors.missing_emails,
        errors: @errors
      )
    end

    private

    attr_reader :envelope, :admin, :authors, :id_map

    def import_records
      raise NotImplementedError
    end

    def records
      envelope.records
    end

    def resolve_author(email)
      authors.resolve(email)
    end

    def remember(record_type, source_id, local_id)
      id_map.remember(record_type, source_id, local_id)
    end

    def imported!(source_id, record)
      remember(record.class.name, source_id, record.id)
      @imported += 1
      record
    end

    def skipped!(source_id, record)
      remember(record.class.name, source_id, record.id)
      @skipped += 1
      record
    end

    def failed!(source_id, message)
      @failed += 1
      @errors << { id: source_id, error: message }
      nil
    end

    def find_verse(reference)
      result = VerseReferenceResolver.call(reference, allow_range: false)
      return [nil, result.error] if result.error

      [result.verse, nil]
    end

    def assign_html(record, field, html)
      restored = Html.import(html, id_map: id_map)
      record.public_send("#{field}=", restored)
    end
  end
end
