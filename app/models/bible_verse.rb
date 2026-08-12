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

  # Chiasms that start or end on this verse
  has_many :chiasms_as_start, class_name: 'Chiasm', foreign_key: 'start_verse_id', dependent: :restrict_with_error
  has_many :chiasms_as_end, class_name: 'Chiasm', foreign_key: 'end_verse_id', dependent: :restrict_with_error
  
  # Topics
  has_many :verse_topics, dependent: :destroy
  has_many :topics, through: :verse_topics

  # Mentions from notes/comments that link to this verse
  has_many :verse_mentions, dependent: :destroy
  
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

  # Published notes/comments that link to this verse (excluding comments on this verse itself)
  def published_mentions
    mentions = VerseMention
      .where(id: published_note_mention_ids)
      .or(VerseMention.where(id: published_comment_mention_ids))
      .includes(:mentionable)
      .order(created_at: :desc)
      .to_a

    preload_mentionables(mentions)
    mentions
  end

  private

  def published_note_mention_ids
    verse_mentions
      .where(mentionable_type: "Note")
      .joins("INNER JOIN notes ON notes.id = verse_mentions.mentionable_id")
      .where(notes: { status: "published" })
      .select(:id)
  end

  def published_comment_mention_ids
    verse_mentions
      .where(mentionable_type: "Comment")
      .joins("INNER JOIN comments ON comments.id = verse_mentions.mentionable_id")
      .joins(<<~SQL.squish)
        LEFT JOIN notes AS comment_notes
          ON comments.commentable_type = 'Note'
          AND comments.commentable_id = comment_notes.id
      SQL
      .joins(<<~SQL.squish)
        LEFT JOIN bible_verses AS comment_verses
          ON comments.commentable_type = 'BibleVerse'
          AND comments.commentable_id = comment_verses.id
      SQL
      .joins(<<~SQL.squish)
        LEFT JOIN bible_verses AS comment_end_verses
          ON comments.end_verse_id = comment_end_verses.id
      SQL
      .where(<<~SQL.squish, id: id, book: book, chapter: chapter, verse: verse)
        (
          comments.commentable_type = 'Note'
          AND comment_notes.status = 'published'
        )
        OR comments.commentable_type = 'CrossReference'
        OR (
          comments.commentable_type = 'BibleVerse'
          AND NOT (
            comments.commentable_id = :id
            OR (comments.end_verse_id IS NOT NULL AND comments.end_verse_id = :id)
            OR (
              comments.end_verse_id IS NOT NULL
              AND comment_verses.book = :book
              AND comment_verses.chapter = :chapter
              AND comment_verses.verse <= :verse
              AND comment_end_verses.verse >= :verse
            )
          )
        )
      SQL
      .select(:id)
  end

  def preload_mentionables(mentions)
    mentionables = mentions.map(&:mentionable).compact
    notes = mentionables.select { |m| m.is_a?(Note) }
    comments = mentionables.select { |m| m.is_a?(Comment) }

    ActiveRecord::Associations::Preloader.new(records: notes, associations: :user).call if notes.any?
    if comments.any?
      ActiveRecord::Associations::Preloader.new(records: comments, associations: [:user, :commentable]).call
      cross_refs = comments.filter_map { |c| c.commentable if c.commentable.is_a?(CrossReference) }
      ActiveRecord::Associations::Preloader.new(records: cross_refs, associations: [:source_verse, :target_verse, :target_end_verse]).call if cross_refs.any?
    end
  end
end
