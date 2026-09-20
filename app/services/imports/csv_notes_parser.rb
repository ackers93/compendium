require "csv"

module Imports
  class CsvNotesParser
    NoteRow = Struct.new(:reference, :content, keyword_init: true)
    Result = Struct.new(:rows, :skipped, keyword_init: true)

    VERSE_HEADERS = %w[verse reference verse_reference].freeze
    CONTENT_HEADERS = %w[comment content note notes point points].freeze
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

      verse_idx, content_idx, data_rows = locate_columns(table)
      rows = []

      data_rows.each do |csv_row|
        next if csv_row.nil? || csv_row.all? { |cell| cell.to_s.strip.blank? }

        reference = csv_row[verse_idx].to_s.strip
        content = csv_row[content_idx].to_s.strip
        next if reference.blank? && content.blank?

        rows << NoteRow.new(reference: reference, content: content)
      end

      Result.new(rows: rows, skipped: skipped)
    end

    private

    def locate_columns(table)
      headers = table.first.map { |value| normalize_header(value) }
      verse_idx = find_header_index(headers, VERSE_HEADERS)
      content_idx = find_header_index(headers, CONTENT_HEADERS)

      if verse_idx && content_idx && verse_idx != content_idx
        [verse_idx, content_idx, table.drop(1)]
      elsif verse_idx && headers.size >= 2
        fallback_content_idx = verse_idx.zero? ? 1 : 0
        [verse_idx, fallback_content_idx, table.drop(1)]
      else
        [0, 1, table]
      end
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
  end
end
