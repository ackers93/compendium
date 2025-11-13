class BibleVerse < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Cross-references where this verse is the source
  has_many :cross_references_as_source, class_name: 'CrossReference', foreign_key: 'source_verse_id', dependent: :destroy
  has_many :target_verses, through: :cross_references_as_source, source: :target_verse
  
  # Cross-references where this verse is the target
  has_many :cross_references_as_target, class_name: 'CrossReference', foreign_key: 'target_verse_id', dependent: :destroy
  has_many :source_verses, through: :cross_references_as_target, source: :source_verse
  
  validates :book, presence: true
  validates :chapter, presence: true
  validates :verse, presence: true
  validates :text, presence: true
  validates :testament, presence: true, inclusion: { in: ['OT', 'NT'] }
  
  # Get human-readable reference (e.g., "John 3:16")
  def reference
    "#{book} #{chapter}:#{verse}"
  end
  
  # Get all cross-references for this verse (both as source and target)
  def all_cross_references
    CrossReference.where('source_verse_id = ? OR target_verse_id = ?', id, id)
  end
  
  # Get all connected verses (both as source and target)
  def connected_verses
    BibleVerse.where(id: cross_references_as_source.select(:target_verse_id))
              .or(BibleVerse.where(id: cross_references_as_target.select(:source_verse_id)))
  end
  
  # Get cross-references ordered by biblical order
  def ordered_cross_references
    all_cross_references.includes(:source_verse, :target_verse).order(
      Arel.sql("CASE 
        WHEN source_verse_id = #{id} THEN target_verse_id 
        ELSE source_verse_id 
      END")
    )
  end
end