class BibleThread < ApplicationRecord
  include Flaggable
  
  belongs_to :user
  has_many :bible_thread_entries, -> { order(position: :asc) }, dependent: :destroy
  has_many :bible_verses, through: :bible_thread_entries
  
  validates :title, presence: true
  
  accepts_nested_attributes_for :bible_thread_entries, allow_destroy: true
  
  # Get the first verse in the thread
  def first_verse
    bible_thread_entries.first&.bible_verse
  end
  
  # Check if this thread contains a specific verse
  def contains_verse?(verse)
    bible_verses.include?(verse)
  end
  
  # Search by title or verse references
  scope :search_by_title_or_verses, ->(query) {
    return all if query.blank?
    
    query_downcase = query.downcase
    # Build reference pattern (e.g., "John 3:16" or "john 3 16")
    reference_pattern = "%#{query_downcase}%"
    
    where(
      "LOWER(bible_threads.title) LIKE ? OR bible_threads.id IN (
        SELECT DISTINCT bible_thread_entries.bible_thread_id
        FROM bible_thread_entries
        INNER JOIN bible_verses ON bible_thread_entries.bible_verse_id = bible_verses.id
        WHERE LOWER(bible_verses.book) LIKE ? 
           OR LOWER(bible_verses.book || ' ' || bible_verses.chapter || ':' || bible_verses.verse) LIKE ?
           OR LOWER(bible_verses.book || ' ' || bible_verses.chapter || ' ' || bible_verses.verse) LIKE ?
           OR CAST(bible_verses.chapter AS TEXT) LIKE ?
           OR CAST(bible_verses.verse AS TEXT) LIKE ?
      )",
      "%#{query_downcase}%",
      "%#{query_downcase}%",
      reference_pattern,
      reference_pattern,
      "%#{query_downcase}%",
      "%#{query_downcase}%"
    )
  }
end

