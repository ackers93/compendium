require "csv"

module Imports
  class CsvCrossReferencesParser
    Row = Struct.new(:source_reference, :target_reference, :content, keyword_init: true)
    Result = Struct.new(:rows, :skipped, keyword_init: true)

    SOURCE_ONLY_HEADERS = %w[source source_verse source_reference verse1 verse_1 from].freeze
    TARGET_ONLY_HEADERS = %w[target target_verse target_reference verse2 verse_2 to].freeze
    GENERIC_VERSE_HEADERS = %w[verse reference verse_reference].freeze
    CONTENT_HEADERS = %w[comment content note notes point points].freeze
    KNOWN_HEADERS = (
      SOURCE_ONLY_HEADERS + TARGET_ONLY_HEADERS + GENERIC_VERSE_HEADERS + CONTENT_HEADERS
    ).freeze
    SMART_DOUBLE_QUOTES = /[\u201C\u201D\u201E\u201F\u00AB\u00BB\uFF02]/

    def self.parse(io_or_string)
      new(io_or_string).parse
    end

    def initialize(io_or_string)
      @source = io_or_string
    end

    def parse
      table = CSV.parse(read_csv, liberal_parsing: true)
      skipped = Hash.new(0)
      return Result.new(rows: [], skipped: skipped) if table.blank?

      source_idx, target_idx, content_idx, data_rows = locate_columns(table)
      rows = []

      data_rows.each do |csv_row|
        next if csv_row.nil? || csv_row.all? { |cell| cell.to_s.strip.blank? }

        source_reference = csv_row[source_idx].to_s.strip
        target_reference = csv_row[target_idx].to_s.strip
        content = content_idx ? csv_row[content_idx].to_s.strip : ""
        next if source_reference.blank? && target_reference.blank? && content.blank?

        rows << Row.new(
          source_reference: source_reference,
          target_reference: target_reference,
          content: content
        )
      end

      Result.new(rows: rows, skipped: skipped)
    end

    private

    def locate_columns(table)
      headers = table.first.map { |value| normalize_header(value) }
      return [0, 1, 2, table] unless header_row?(headers)

      source_idx, target_idx = verse_column_indices(headers)
      if source_idx && target_idx && source_idx != target_idx
        content_idx = find_header_index(headers, CONTENT_HEADERS)
        content_idx ||= ([0, 1, 2] - [source_idx, target_idx]).first
        [source_idx, target_idx, content_idx, table.drop(1)]
      else
        [0, 1, 2, table.drop(1)]
      end
    end

    def verse_column_indices(headers)
      source_only = find_header_index(headers, SOURCE_ONLY_HEADERS)
      target_only = find_header_index(headers, TARGET_ONLY_HEADERS)
      return [source_only, target_only] if source_only && target_only && source_only != target_only

      verse_idxs = headers.each_index.select do |index|
        KNOWN_VERSE_HEADERS.include?(headers[index])
      end

      if source_only
        [source_only, verse_idxs.find { |index| index != source_only }]
      elsif target_only
        [verse_idxs.find { |index| index != target_only }, target_only]
      elsif verse_idxs.size >= 2
        [verse_idxs[0], verse_idxs[1]]
      else
        [source_only, target_only]
      end
    end

    def header_row?(headers)
      headers.any? { |header| KNOWN_HEADERS.include?(header) }
    end

    def find_header_index(headers, names)
      headers.index { |header| names.include?(header) }
    end

    def normalize_header(value)
      value.to_s.strip.downcase.tr(" ", "_")
    end

    def read_csv
      text = if @source.respond_to?(:read)
        @source.rewind if @source.respond_to?(:rewind)
        @source.read
      else
        @source.to_s
      end
      text = text.to_s
      text = text.dup.force_encoding(Encoding::UTF_8) unless text.encoding == Encoding::UTF_8
      text = text.encode(Encoding::UTF_8, invalid: :replace, undef: :replace) unless text.valid_encoding?
      text.delete_prefix("\uFEFF").gsub(SMART_DOUBLE_QUOTES, '"')
    end

    KNOWN_VERSE_HEADERS = (SOURCE_ONLY_HEADERS + TARGET_ONLY_HEADERS + GENERIC_VERSE_HEADERS).freeze
  end
end
