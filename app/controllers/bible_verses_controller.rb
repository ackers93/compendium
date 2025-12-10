class BibleVersesController < ApplicationController
  before_action :authenticate_user!

  OLD_TESTAMENT_BOOKS = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth',
    '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah',
    'Malachi'
  ].freeze

  NEW_TESTAMENT_BOOKS = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians',
    'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John', 'Jude', 'Revelation'
  ].freeze

  def book_index
    respond_to do |format|
      format.html do
        old_testament_order = OLD_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')
        new_testament_order = NEW_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')

        @old_testament_books = BibleVerse.select("book, CASE book #{old_testament_order} END as book_order").distinct.where(testament: 'OT').order('book_order')
        @new_testament_books = BibleVerse.select("book, CASE book #{new_testament_order} END as book_order").distinct.where(testament: 'NT').order('book_order')
      end
      
      format.json { 
        # For JSON, just return the books in the order defined in the constants
        old_testament = BibleVerse.where(testament: 'OT').distinct.pluck(:book)
        new_testament = BibleVerse.where(testament: 'NT').distinct.pluck(:book)
        
        # Sort them according to the predefined order
        old_testament_sorted = OLD_TESTAMENT_BOOKS.select { |book| old_testament.include?(book) }
        new_testament_sorted = NEW_TESTAMENT_BOOKS.select { |book| new_testament.include?(book) }
        
        render json: { 
          old_testament: old_testament_sorted,
          new_testament: new_testament_sorted
        } 
      }
    end
  end

  def chapters
    @book = params[:book]
    @chapters = BibleVerse.where(book: @book).select(:chapter).distinct.order(:chapter)
    
    respond_to do |format|
      format.html
      format.json { render json: { chapters: @chapters.pluck(:chapter) } }
    end
  end

  def verses
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verses = BibleVerse.where(book: @book, chapter: @chapter).order(:verse)
    
    respond_to do |format|
      format.html
      format.json { render json: { verses: @verses.as_json(only: [:id, :verse, :text]) } }
    end
  end
  
  def verse_picker
    old_testament_order = OLD_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')
    new_testament_order = NEW_TESTAMENT_BOOKS.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')

    @old_testament_books = BibleVerse.select("book, CASE book #{old_testament_order} END as book_order").distinct.where(testament: 'OT').order('book_order')
    @new_testament_books = BibleVerse.select("book, CASE book #{new_testament_order} END as book_order").distinct.where(testament: 'NT').order('book_order')
  end

  def show
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verse = params[:verse].to_i
    @bible_verse = BibleVerse.find_by(book: @book, chapter: @chapter, verse: @verse)
    
    if @bible_verse.nil?
      redirect_to bible_verse_chapters_path(book: @book), alert: "Verse not found"
    end
  end

  def autocomplete
    query = params[:q].to_s.strip
    results = []
    
    return render json: [] if query.blank?
    
    query_downcase = query.downcase
    
    # Try to parse the query: book, book chapter, or book chapter:verse
    # Patterns: "Genesis", "Genesis 1", "Genesis 1:1", "John 3:16", "Gen 1:1"
    book_match = nil
    chapter_match = nil
    verse_match = nil
    
    # Try to match "book chapter:verse" pattern (e.g., "Genesis 1:1", "John 3:16")
    if query.match?(/^(.+?)\s+(\d+):(\d+)$/i)
      parts = query.match(/^(.+?)\s+(\d+):(\d+)$/i)
      book_match = parts[1].strip
      chapter_match = parts[2].to_i
      verse_match = parts[3].to_i
    # Try to match "book chapter" pattern (e.g., "Genesis 1", "John 3")
    elsif query.match?(/^(.+?)\s+(\d+)$/i)
      parts = query.match(/^(.+?)\s+(\d+)$/i)
      book_match = parts[1].strip
      chapter_match = parts[2].to_i
    else
      # Just book name (e.g., "Genesis", "Gen")
      book_match = query.strip
    end
    
    # Find matching book names (case-insensitive, partial match)
    all_books = OLD_TESTAMENT_BOOKS + NEW_TESTAMENT_BOOKS
    matching_books = all_books.select do |book|
      book.downcase.start_with?(book_match.downcase) || 
      book.downcase.include?(book_match.downcase)
    end.sort_by { |book| book.downcase.start_with?(book_match.downcase) ? 0 : 1 }
    
    # If we have book, chapter, and verse, search for exact verse matches
    if book_match && chapter_match && verse_match
      matching_books.each do |book|
        verse = BibleVerse.where("LOWER(book) = ? AND chapter = ? AND verse = ?", 
                                 book.downcase, chapter_match, verse_match).first
        if verse
          results << {
            type: "verse",
            book: verse.book,
            chapter: verse.chapter,
            verse: verse.verse
          }
          break # Only need one match
        end
      end
    end
    
    # If we have book and chapter (but no verse), search for chapter matches
    if book_match && chapter_match && !verse_match
      matching_books.each do |book|
        chapter = BibleVerse.where("LOWER(book) = ? AND chapter = ?", 
                                   book.downcase, chapter_match).first
        if chapter
          results << {
            type: "chapter",
            book: chapter.book,
            chapter: chapter.chapter
          }
          break # Only need one match
        end
      end
    end
    
    # Always include matching books (if not already in results)
    matching_books.first(10).each do |book|
      # Skip if this book is already in results
      next if results.any? { |r| r[:book] == book }
      
      results << {
        type: "book",
        book: book
      }
    end
    
    # Limit total results
    render json: results.first(10)
  end
end