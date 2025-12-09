class Topic < ApplicationRecord
  has_many :verse_topics, dependent: :destroy
  has_many :bible_verses, through: :verse_topics
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  # Normalize name before saving
  before_save :normalize_name
  
  # Case-insensitive search for autocomplete
  scope :search_by_name, ->(query) { where("LOWER(name) LIKE ?", "%#{query.downcase}%") }
  
  # Search by name or verse references
  scope :search_by_name_or_verses, ->(query) {
    return all if query.blank?
    
    query_downcase = query.downcase
    # Build reference pattern (e.g., "John 3:16" or "john 3 16")
    reference_pattern = "%#{query_downcase}%"
    
    where(
      "LOWER(topics.name) LIKE ? OR topics.id IN (
        SELECT DISTINCT verse_topics.topic_id
        FROM verse_topics
        INNER JOIN bible_verses ON verse_topics.bible_verse_id = bible_verses.id
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
  
  # Find or create by name (case-insensitive)
  def self.find_or_create_by_name(name)
    normalized_name = name.to_s.strip
    find_by("LOWER(name) = ?", normalized_name.downcase) || create(name: normalized_name)
  end
  
  private
  
  def normalize_name
    self.name = name.to_s.strip if name.present?
  end
end
