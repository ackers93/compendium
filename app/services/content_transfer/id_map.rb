# frozen_string_literal: true

module ContentTransfer
  class IdMap
    def initialize(source:)
      @source = source.to_s.presence || "compendium"
    end

    def remember(record_type, source_id, local_id)
      return if source_id.blank? || local_id.blank?

      mapping = ContentImportMapping.find_or_initialize_by(
        source: @source,
        record_type: record_type.to_s,
        source_id: source_id
      )
      mapping.local_id = local_id
      mapping.save!
      local_id
    end

    def lookup(record_type, source_id)
      return nil if source_id.blank?

      ContentImportMapping.find_by(
        source: @source,
        record_type: record_type.to_s,
        source_id: source_id
      )&.local_id
    end

    def find_record(klass, source_id)
      local_id = lookup(klass.name, source_id)
      return nil unless local_id

      klass.find_by(id: local_id)
    end
  end
end
