require "csv"

module Imports
  class OliveTreeNotesParser
    NoteRow = Struct.new(:reference, :content, :raw_start, :raw_end, keyword_init: true)
    Result = Struct.new(:rows, :skipped, keyword_init: true)

    OLIVE_TREE_REF = /\A(.+):(\d+):(\d+)\z/

    def self.parse(io_or_string)
      new(io_or_string).parse
    end

    def initialize(io_or_string)
      @source = io_or_string
    end

    def parse
      rows = []
      skipped = Hash.new(0)

      CSV.parse(read_csv, headers: true, liberal_parsing: true) do |csv_row|
        type = csv_row["type"].to_s.strip
        unless type.match?(/\Anote\z/i)
          skipped[:non_note] += 1
          next
        end

        content = csv_row["content"].to_s.strip
        raw_start = csv_row["reference_start"].to_s.strip
        raw_end = csv_row["reference_end"].to_s.strip

        if content.blank?
          skipped[:empty_content] += 1
          next
        end

        if raw_start.blank?
          skipped[:missing_reference] += 1
          next
        end

        start_ref = normalize_reference(raw_start)
        unless start_ref
          skipped[:unparseable_reference] += 1
          next
        end

        end_ref = raw_end.present? && raw_end != raw_start ? normalize_reference(raw_end) : nil
        if raw_end.present? && raw_end != raw_start && end_ref.nil?
          skipped[:unparseable_reference] += 1
          next
        end

        reference = build_display_reference(start_ref, end_ref)
        unless reference
          skipped[:unparseable_reference] += 1
          next
        end

        rows << NoteRow.new(
          reference: reference,
          content: content,
          raw_start: raw_start,
          raw_end: raw_end.presence
        )
      end

      Result.new(rows: rows, skipped: skipped)
    end

    private

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
      text.delete_prefix("\uFEFF")
    end

    def normalize_reference(raw)
      match = raw.to_s.strip.match(OLIVE_TREE_REF)
      return nil unless match

      book = match[1].strip
      chapter = match[2]
      verse = match[3]
      return nil if book.blank?

      "#{book} #{chapter}:#{verse}"
    end

    def build_display_reference(start_ref, end_ref)
      return start_ref unless end_ref

      start_parsed = VerseReferenceParser.parse(start_ref)
      end_parsed = VerseReferenceParser.parse(end_ref)
      return nil unless start_parsed && end_parsed
      return nil unless start_parsed.book == end_parsed.book && start_parsed.chapter == end_parsed.chapter

      if end_parsed.start_verse > start_parsed.start_verse
        "#{start_parsed.book} #{start_parsed.chapter}:#{start_parsed.start_verse}-#{end_parsed.start_verse}"
      else
        start_ref
      end
    end
  end
end
