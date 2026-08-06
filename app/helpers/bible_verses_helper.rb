module BibleVersesHelper
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

  private

  def all_bible_books
    BibleVersesController::OLD_TESTAMENT_BOOKS + BibleVersesController::NEW_TESTAMENT_BOOKS
  end
end
