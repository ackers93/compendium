class VerseReferenceParser
  ParseResult = Struct.new(:book, :chapter, :start_verse, :end_verse, keyword_init: true) do
    def display
      base = "#{book} #{chapter}:#{start_verse}"
      end_verse ? "#{base}-#{end_verse}" : base
    end
  end

  ALL_BOOKS = (
    BibleVersesController::OLD_TESTAMENT_BOOKS +
    BibleVersesController::NEW_TESTAMENT_BOOKS
  ).freeze

  ABBREVIATIONS = {
    "gen" => "Genesis", "ge" => "Genesis",
    "ex" => "Exodus", "exo" => "Exodus",
    "lev" => "Leviticus", "lv" => "Leviticus",
    "num" => "Numbers", "nm" => "Numbers",
    "deut" => "Deuteronomy", "dt" => "Deuteronomy",
    "jos" => "Joshua", "josh" => "Joshua",
    "judg" => "Judges", "jdg" => "Judges",
    "rut" => "Ruth",
    "1sa" => "1 Samuel", "1sam" => "1 Samuel",
    "2sa" => "2 Samuel", "2sam" => "2 Samuel",
    "1ki" => "1 Kings", "1kings" => "1 Kings",
    "2ki" => "2 Kings", "2kings" => "2 Kings",
    "1ch" => "1 Chronicles", "1chr" => "1 Chronicles", "1chron" => "1 Chronicles",
    "2ch" => "2 Chronicles", "2chr" => "2 Chronicles", "2chron" => "2 Chronicles",
    "ezr" => "Ezra",
    "neh" => "Nehemiah",
    "est" => "Esther",
    "job" => "Job",
    "ps" => "Psalms", "psa" => "Psalms", "psalm" => "Psalms",
    "prov" => "Proverbs", "pr" => "Proverbs",
    "eccl" => "Ecclesiastes", "ecc" => "Ecclesiastes",
    "song" => "Song of Solomon", "sos" => "Song of Solomon", "sol" => "Song of Solomon",
    "isa" => "Isaiah", "is" => "Isaiah",
    "jer" => "Jeremiah",
    "lam" => "Lamentations",
    "ezk" => "Ezekiel", "ezek" => "Ezekiel",
    "dan" => "Daniel",
    "hos" => "Hosea",
    "joe" => "Joel", "jl" => "Joel",
    "amo" => "Amos",
    "oba" => "Obadiah", "obad" => "Obadiah",
    "jon" => "Jonah",
    "mic" => "Micah",
    "nah" => "Nahum",
    "hab" => "Habakkuk",
    "zep" => "Zephaniah", "zeph" => "Zephaniah",
    "hag" => "Haggai",
    "zec" => "Zechariah", "zech" => "Zechariah",
    "mal" => "Malachi",
    "matt" => "Matthew", "mt" => "Matthew",
    "mk" => "Mark", "mar" => "Mark",
    "lk" => "Luke",
    "jn" => "John", "joh" => "John",
    "acts" => "Acts", "ac" => "Acts",
    "rom" => "Romans", "ro" => "Romans",
    "1co" => "1 Corinthians", "1cor" => "1 Corinthians",
    "2co" => "2 Corinthians", "2cor" => "2 Corinthians",
    "gal" => "Galatians", "ga" => "Galatians",
    "eph" => "Ephesians",
    "phil" => "Philippians", "php" => "Philippians",
    "col" => "Colossians",
    "1th" => "1 Thessalonians", "1thess" => "1 Thessalonians",
    "2th" => "2 Thessalonians", "2thess" => "2 Thessalonians",
    "1ti" => "1 Timothy", "1tim" => "1 Timothy",
    "2ti" => "2 Timothy", "2tim" => "2 Timothy",
    "tit" => "Titus",
    "phm" => "Philemon", "philem" => "Philemon",
    "heb" => "Hebrews",
    "jas" => "James", "jam" => "James",
    "1pe" => "1 Peter", "1pet" => "1 Peter",
    "2pe" => "2 Peter", "2pet" => "2 Peter",
    "1jn" => "1 John", "1jo" => "1 John",
    "2jn" => "2 John", "2jo" => "2 John",
    "3jn" => "3 John", "3jo" => "3 John",
    "jud" => "Jude",
    "rev" => "Revelation", "re" => "Revelation"
  }.freeze

  SPACED_PATTERN = /\A(.+?)\s+(\d+):(\d+)(?:-(\d+))?\z/i
  COMPACT_PATTERN = /\A(.+?)(\d+):(\d+)(?:-(\d+))?\z/i

  def self.parse(reference)
    new(reference).parse
  end

  def initialize(reference)
    @reference = reference.to_s.strip
  end

  def parse
    return nil if @reference.blank?

    normalized = @reference.gsub(/\s+-\s*$/, "").strip

    match = normalized.match(SPACED_PATTERN) || normalized.match(COMPACT_PATTERN)
    return nil unless match

    book_token = match[1].strip
    chapter = match[2].to_i
    start_verse = match[3].to_i
    end_verse = match[4]&.to_i

    book = resolve_book(book_token)
    return nil unless book
    return nil if chapter.zero? || start_verse.zero?
    return nil if end_verse && end_verse <= start_verse

    ParseResult.new(
      book: book,
      chapter: chapter,
      start_verse: start_verse,
      end_verse: end_verse
    )
  end

  private

  def resolve_book(token)
    normalized = token.downcase.gsub(/\./, "").gsub(/\s+/, " ").strip
    return nil if normalized.blank?

    exact = ALL_BOOKS.find { |book| book.downcase == normalized }
    return exact if exact

    return ABBREVIATIONS[normalized] if ABBREVIATIONS.key?(normalized)

    if normalized.match?(/\A\d+\s/)
      numbered_matches = ALL_BOOKS.select { |book| book.downcase.start_with?(normalized) }
      return pick_best_match(numbered_matches, normalized)
    end

    if normalized.match?(/\A\d+[a-z]+/)
      number = normalized[/\A\d+/]
      rest = normalized[number.length..]
      return ABBREVIATIONS[normalized] if ABBREVIATIONS.key?(normalized)

      candidates = ALL_BOOKS.select { |book| book.downcase.start_with?("#{number} ") }
      found = pick_best_match(candidates, rest, numbered: true)
      return found if found
    end

    prefix_matches = ALL_BOOKS.select do |book|
      downcased = book.downcase
      compact = downcased.gsub(/\s+/, "")
      downcased.start_with?(normalized) || compact.start_with?(normalized)
    end
    found = pick_best_match(prefix_matches, normalized)
    return found if found

    include_matches = ALL_BOOKS.select { |book| book.downcase.include?(normalized) }
    pick_best_match(include_matches, normalized)
  end

  def pick_best_match(candidates, token, numbered: false)
    return nil if candidates.empty?
    return candidates.first if candidates.one?

    if numbered
      return candidates.find { |book| book.downcase.gsub(/\s+/, "").start_with?("#{token.downcase}") } ||
             candidates.find { |book| book.downcase.include?(token) }
    end

    candidates.min_by do |book|
      compact = book.downcase.gsub(/\s+/, "")
      if book.downcase == token || compact == token
        0
      elsif book.downcase.start_with?(token) || compact.start_with?(token)
        1 + book.length
      else
        2 + book.length
      end
    end
  end
end
