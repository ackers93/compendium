class VerseReferenceResolver
  Result = Struct.new(:parsed, :verse, :end_verse, :error, keyword_init: true)

  def self.call(reference, allow_range: true)
    new(reference, allow_range: allow_range).resolve
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
