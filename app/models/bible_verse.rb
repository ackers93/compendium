class BibleVerse < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :comments_as_end_verse, class_name: 'Comment', foreign_key: 'end_verse_id', dependent: :nullify
  
  # Cross-references where this verse is the source
  has_many :cross_references_as_source, class_name: 'CrossReference', foreign_key: 'source_verse_id', dependent: :destroy
  has_many :target_verses, through: :cross_references_as_source, source: :target_verse
  
  # Cross-references where this verse is the target
  has_many :cross_references_as_target, class_name: 'CrossReference', foreign_key: 'target_verse_id', dependent: :destroy
  has_many :source_verses, through: :cross_references_as_target, source: :source_verse
  
  # Cross-references where this verse is the end of a target range
  has_many :cross_references_as_target_end, class_name: 'CrossReference', foreign_key: 'target_end_verse_id', dependent: :nullify
  
  # Bible threads
  has_many :bible_thread_entries, dependent: :destroy
  has_many :bible_threads, through: :bible_thread_entries
  
  # Topics
  has_many :verse_topics, dependent: :destroy
  has_many :topics, through: :verse_topics
  
  validates :book, presence: true
  validates :chapter, presence: true
  validates :verse, presence: true
  validates :text, presence: true
  validates :testament, presence: true, inclusion: { in: ['OT', 'NT'] }
  
  # Get human-readable reference (e.g., "John 3:16")
  def reference
    "#{book} #{chapter}:#{verse}"
  end
  
  # Comments on this verse, plus ranged comments that include it
  def visible_comments
    Comment
      .joins("INNER JOIN bible_verses AS cv ON comments.commentable_type = 'BibleVerse' AND comments.commentable_id = cv.id")
      .joins("LEFT JOIN bible_verses AS cev ON comments.end_verse_id = cev.id")
      .where(
        "(comments.commentable_id = :id AND comments.commentable_type = 'BibleVerse')
         OR comments.end_verse_id = :id
         OR (
           comments.end_verse_id IS NOT NULL
           AND cv.book = :book
           AND cv.chapter = :chapter
           AND cv.verse <= :verse
           AND cev.verse >= :verse
         )",
        id: id, book: book, chapter: chapter, verse: verse
      )
  end
  
  # Get all cross-references for this verse (as source, target start/end, or within a target range)
  def all_cross_references
    CrossReference
      .joins("INNER JOIN bible_verses AS cr_target ON cr_target.id = cross_references.target_verse_id")
      .joins("LEFT JOIN bible_verses AS cr_target_end ON cr_target_end.id = cross_references.target_end_verse_id")
      .where(
        "cross_references.source_verse_id = :id
         OR cross_references.target_verse_id = :id
         OR cross_references.target_end_verse_id = :id
         OR (
           cross_references.target_end_verse_id IS NOT NULL
           AND cr_target.book = :book
           AND cr_target.chapter = :chapter
           AND cr_target.verse <= :verse
           AND cr_target_end.verse >= :verse
         )",
        id: id, book: book, chapter: chapter, verse: verse
      )
  end
  
  # Get all connected verses (both as source and target)
  def connected_verses
    BibleVerse.where(id: cross_references_as_source.select(:target_verse_id))
              .or(BibleVerse.where(id: cross_references_as_target.select(:source_verse_id)))
  end
  
  # Get cross-references ordered by biblical order
  def ordered_cross_references
    all_cross_references.includes(:source_verse, :target_verse, :target_end_verse).order(
      Arel.sql("CASE 
        WHEN source_verse_id = #{id} THEN target_verse_id 
        ELSE source_verse_id 
      END")
    )
  end
end
