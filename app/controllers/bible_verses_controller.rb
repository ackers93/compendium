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
end