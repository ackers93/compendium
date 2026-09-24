# frozen_string_literal: true

class VerseReferenceScanner
  Match = Struct.new(:text, :start_offset, :end_offset, :parsed, :verse, :end_verse, keyword_init: true)

  BOOK_TOKENS = (
    VerseReferenceParser::ALL_BOOKS + VerseReferenceParser::ABBREVIATIONS.keys
  ).uniq.sort_by { |token| -token.length }.freeze

  SHORT_ABBREVIATIONS = VerseReferenceParser::ABBREVIATIONS.keys
    .select { |key| key.gsub(/\d+/, "").length <= 2 }
    .map(&:downcase)
    .to_set
    .freeze

  BOOK_ALTERNATION = BOOK_TOKENS.map { |token|
    Regexp.escape(token).gsub(/\\ /, '\s+')
  }.join("|").freeze

  # Book (optional period), then optional space/colon, then chapter:verse[-end]
  PATTERN = /
    (?<!\w)
    (#{BOOK_ALTERNATION})
    (\.)?
    (?:\s+|:)?
    (\d+):(\d+)(?:-(\d+))?
    (?!\w)
  /ix.freeze

  def self.scan(text, resolve: true)
    new(text, resolve: resolve).scan
  end

  def initialize(text, resolve: true)
    @text = text.to_s
    @resolve = resolve
  end

  def scan
    matches = []
    last_end = 0

    @text.to_enum(:scan, PATTERN).each do
      md = Regexp.last_match
      next if md.begin(0) < last_end

      raw = md[0]
      book_token = "#{md[1]}#{md[2]}"
      next unless intentional_book_token?(book_token)

      parsed = VerseReferenceParser.parse(raw)
      next unless parsed

      verse = nil
      end_verse = nil
      if @resolve
        result = VerseReferenceResolver.call(raw, allow_range: true)
        next if result.error

        verse = result.verse
        end_verse = result.end_verse
      end

      matches << Match.new(
        text: raw,
        start_offset: md.begin(0),
        end_offset: md.end(0),
        parsed: parsed,
        verse: verse,
        end_verse: end_verse
      )
      last_end = md.end(0)
    end

    matches
  end

  private

  def intentional_book_token?(book_token)
    normalized = book_token.downcase.gsub(/\./, "").gsub(/\s+/, " ").strip
    return true if VerseReferenceParser::ALL_BOOKS.any? { |book| book.downcase == normalized }

    abbrev_key = normalized.gsub(/\s+/, "")
    return true unless SHORT_ABBREVIATIONS.include?(abbrev_key)

    # Numbered abbreviations (1ki, 2co) are unambiguous in lowercase.
    return true if abbrev_key.match?(/\A\d/)
    return true if book_token.include?(".")

    first_letter = book_token[/[A-Za-z]/]
    first_letter.present? && first_letter == first_letter.upcase
  end
end
