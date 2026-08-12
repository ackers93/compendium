module BibleVersesHelper
  RANGE_COMMENT_COLORS = RangeColors::COLORS

  # Returns { book:, chapter: } for the previous chapter, or nil at Genesis 1.
  def previous_bible_chapter(book, chapter)
    chapter = chapter.to_i
    if chapter > 1
      { book: book, chapter: chapter - 1 }
    else
      index = all_bible_books.index(book)
      return nil if index.nil? || index.zero?

      prev_book = all_bible_books[index - 1]
      prev_chapter = BibleVerse.where(book: prev_book).maximum(:chapter)
      return nil unless prev_chapter

      { book: prev_book, chapter: prev_chapter }
    end
  end

  # Returns { book:, chapter: } for the next chapter, or nil at Revelation's last chapter.
  def next_bible_chapter(book, chapter)
    chapter = chapter.to_i
    max_chapter = BibleVerse.where(book: book).maximum(:chapter)
    return nil unless max_chapter

    if chapter < max_chapter
      { book: book, chapter: chapter + 1 }
    else
      index = all_bible_books.index(book)
      return nil if index.nil? || index >= all_bible_books.length - 1

      next_book = all_bible_books[index + 1]
      { book: next_book, chapter: 1 }
    end
  end

  def bible_chapter_label(ref)
    return nil unless ref

    "#{ref[:book]} #{ref[:chapter]}"
  end

  # Assign stacking tracks + colors for overlapping ranged comments in a chapter.
  # Returns a hash: comment_id => { track:, color:, start_verse:, end_verse: }
  def assign_range_comment_tracks(ranged_comments)
    ranges = ranged_comments.select(&:range?).sort_by do |comment|
      [comment.commentable.verse, comment.end_verse.verse, comment.id]
    end

    occupied_tracks = []
    assignments = {}

    ranges.each do |comment|
      start_v = comment.commentable.verse
      end_v = comment.end_verse.verse

      track = occupied_tracks.find_index do |intervals|
        intervals.none? { |s, e| start_v <= e && end_v >= s }
      end

      if track.nil?
        track = occupied_tracks.length
        occupied_tracks << []
      end

      occupied_tracks[track] << [start_v, end_v]
      assignments[comment.id] = {
        track: track,
        color: RangeColors.css_var_at(track),
        start_verse: start_v,
        end_verse: end_v
      }
    end

    assignments
  end

  def range_rail_segment_for(verse_number, assignment)
    start_v = assignment[:start_verse]
    end_v = assignment[:end_verse]
    return nil if verse_number < start_v || verse_number > end_v

    if verse_number == start_v && verse_number == end_v
      'single'
    elsif verse_number == start_v
      'start'
    elsif verse_number == end_v
      'end'
    else
      'middle'
    end
  end

  private

  def all_bible_books
    BibleVersesController::OLD_TESTAMENT_BOOKS + BibleVersesController::NEW_TESTAMENT_BOOKS
  end
end
