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
      format.html do
        @first_verse = BibleVerse.where(book: @book).order(:chapter, :verse).first
        @book_level_comments = Comment.covering_book(@book)
                                      .includes(:user, :end_verse, :commentable, :rich_text_content)
                                      .order(created_at: :desc)
                                      .to_a
        @book_level_children = Comment.thread_children_for(@book_level_comments)
      end
      format.json { render json: { chapters: @chapters.pluck(:chapter) } }
    end
  end

  def verses
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verses = BibleVerse.where(book: @book, chapter: @chapter).order(:verse)

    respond_to do |format|
      format.html do
        verse_ids = @verses.map(&:id)
        @chapter_comments_by_verse_id = Comment
          .where(commentable_type: 'BibleVerse', commentable_id: verse_ids)
          .verse_coverage
          .includes(:user, :end_verse, :commentable, :rich_text_content)
          .order(created_at: :desc)
          .group_by(&:commentable_id)

        @chapter_level_comments = Comment.covering_chapter(@book, @chapter)
                                         .includes(:user, :end_verse, :commentable, :rich_text_content)
                                         .order(created_at: :desc)
                                         .to_a
        @chapter_level_children = Comment.thread_children_for(@chapter_level_comments)

        ranged = @chapter_comments_by_verse_id.values.flatten.select(&:range?)
        @range_comment_tracks = view_context.assign_range_comment_tracks(ranged)
        @range_track_count = @range_comment_tracks.values.map { |a| a[:track] }.max.then { |m| m ? m + 1 : 0 }

        max_verse = @verses.maximum(:verse) || 1
        overlapping_chiasms = Chiasm
          .includes(:user, :start_verse, :end_verse)
          .joins("INNER JOIN bible_verses AS chiasm_start ON chiasm_start.id = chiasms.start_verse_id")
          .joins("INNER JOIN bible_verses AS chiasm_end ON chiasm_end.id = chiasms.end_verse_id")
          .where("chiasm_start.book = ?", @book)
          .where(
            "(chiasm_start.chapter < :c OR (chiasm_start.chapter = :c AND chiasm_start.verse <= :max_v))",
            c: @chapter, max_v: max_verse
          )
          .where(
            "(chiasm_end.chapter > :c OR (chiasm_end.chapter = :c AND chiasm_end.verse >= 1))",
            c: @chapter
          )

        @chiasms_by_verse_id = {}
        @verses.each do |verse|
          @chiasms_by_verse_id[verse.id] = overlapping_chiasms.select { |c| c.contains_verse?(verse) }
        end
      end
      format.json { render json: { verses: @verses.as_json(only: [:id, :verse, :text]) } }
    end
  end
  
  def show
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verse = params[:verse].to_i
    @bible_verse = BibleVerse.find_by(book: @book, chapter: @chapter, verse: @verse)
    
    if @bible_verse.nil?
      redirect_to bible_verse_chapters_path(book: @book), alert: "Verse not found"
    else
      @published_mentions = @bible_verse.published_mentions
      @verse_chiasms = Chiasm.containing_verse(@bible_verse).includes(:user, :chiasm_limbs)
    end
  end

  def autocomplete
    query = params[:q].to_s.strip
    return render json: [] if query.blank?

    render json: reference_search_results(query, include_text: false).first(10)
  end

  def quick_search
    query = params[:q].to_s.strip
    return render json: { references: [], content: [] } if query.blank?

    references = reference_search_results(query, include_text: true).first(10)
    content = if query.length >= 3
      BibleVerse.search_by_text(query).map do |verse|
        {
          type: "content",
          book: verse.book,
          chapter: verse.chapter,
          verse: verse.verse,
          text: verse.text
        }
      end
    else
      []
    end

    render json: { references: references, content: content }
  end

  private

  def reference_search_results(query, include_text:)
    results = []
    book_match = nil
    chapter_match = nil
    verse_match = nil

    # Patterns: "Genesis", "Genesis 1", "Genesis 1:1", "John 3:16"
    if query.match?(/^(.+?)\s+(\d+):(\d+)$/i)
      parts = query.match(/^(.+?)\s+(\d+):(\d+)$/i)
      book_match = parts[1].strip
      chapter_match = parts[2].to_i
      verse_match = parts[3].to_i
    elsif query.match?(/^(.+?)\s+(\d+)$/i)
      parts = query.match(/^(.+?)\s+(\d+)$/i)
      book_match = parts[1].strip
      chapter_match = parts[2].to_i
    else
      book_match = query.strip
    end

    all_books = OLD_TESTAMENT_BOOKS + NEW_TESTAMENT_BOOKS
    matching_books = all_books.select do |book|
      book.downcase.start_with?(book_match.downcase) ||
        book.downcase.include?(book_match.downcase)
    end.sort_by { |book| book.downcase.start_with?(book_match.downcase) ? 0 : 1 }

    if book_match && chapter_match && verse_match
      matching_books.each do |book|
        verse = BibleVerse.where("LOWER(book) = ? AND chapter = ? AND verse = ?",
                                 book.downcase, chapter_match, verse_match).first
        if verse
          result = {
            type: "verse",
            book: verse.book,
            chapter: verse.chapter,
            verse: verse.verse
          }
          result[:text] = verse.text if include_text
          results << result
          break
        end
      end
    end

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
          break
        end
      end
    end

    matching_books.first(10).each do |book|
      next if results.any? { |r| r[:book] == book }

      results << {
        type: "book",
        book: book
      }
    end

    results
  end
end