class VerseReferenceResolver
  Result = Struct.new(:parsed, :verse, :end_verse, :error, keyword_init: true)
  ParseListResult = Struct.new(:verses, :errors, keyword_init: true)

  def self.call(reference, allow_range: true)
    new(reference, allow_range: allow_range).resolve
  end

  def self.parse_list(refs_string)
    refs = refs_string.to_s.split(/[,;\n]+/).map(&:strip).reject(&:blank?)
    return ParseListResult.new(verses: [], errors: ["Add at least one verse reference."]) if refs.empty?

    verses = []
    errors = []
    seen_ids = {}

    refs.each do |ref|
      result = call(ref, allow_range: true)
      if result.error
        errors << "#{ref}: #{result.error}"
        next
      end

      expanded = result.end_verse ? expand_range(result.verse, result.end_verse) : [result.verse]
      if expanded.empty?
        errors << "#{ref}: No verses found."
        next
      end

      expanded.each do |verse|
        next if seen_ids[verse.id]

        seen_ids[verse.id] = true
        verses << verse
      end
    end

    ParseListResult.new(verses: verses, errors: errors)
  end

  def self.expand_range(start_verse, end_verse)
    BibleVerse.where(book: start_verse.book, chapter: start_verse.chapter)
              .where(verse: start_verse.verse..end_verse.verse)
              .order(:verse)
              .to_a
  end

  def initialize(reference, allow_range: true)
    @reference = reference
    @allow_range = allow_range
  end

  def resolve
    parsed = VerseReferenceParser.parse(@reference)
    unless parsed
      return Result.new(error: "Could not parse \"#{@reference}\". Try formats like gen1:1, Gen 1:1, or Genesis 1:1-4.")
    end

    if !@allow_range && parsed.end_verse
      return Result.new(error: "Must be a single verse, not a range.")
    end

    verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.start_verse)
    unless verse
      return Result.new(error: "Verse not found: #{parsed.display}")
    end

    end_verse = nil
    if parsed.end_verse
      end_verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.end_verse)
      unless end_verse
        return Result.new(error: "End verse not found: #{parsed.book} #{parsed.chapter}:#{parsed.end_verse}")
      end
    end

    Result.new(parsed: parsed, verse: verse, end_verse: end_verse)
  end
end
