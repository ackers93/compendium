class Chiasm < ApplicationRecord
  include Flaggable

  belongs_to :user
  belongs_to :start_verse, class_name: 'BibleVerse'
  belongs_to :end_verse, class_name: 'BibleVerse'
  has_many :chiasm_limbs, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :chiasm
  has_many :topic_items, as: :itemable, dependent: :destroy

  validates :title, presence: true
  validates :start_verse, :end_verse, presence: true
  validate :range_must_be_valid
  validates_associated :chiasm_limbs

  accepts_nested_attributes_for :chiasm_limbs, allow_destroy: true

  scope :search_by_title_or_verses, ->(query) {
    return all if query.blank?

    query_downcase = query.downcase
    reference_pattern = "%#{query_downcase}%"

    where(
      "LOWER(chiasms.title) LIKE ? OR chiasms.id IN (
        SELECT DISTINCT c.id
        FROM chiasms c
        INNER JOIN bible_verses sv ON sv.id = c.start_verse_id
        INNER JOIN bible_verses ev ON ev.id = c.end_verse_id
        WHERE LOWER(sv.book) LIKE ?
           OR LOWER(sv.book || ' ' || sv.chapter || ':' || sv.verse) LIKE ?
           OR LOWER(ev.book || ' ' || ev.chapter || ':' || ev.verse) LIKE ?
           OR LOWER(sv.book || ' ' || sv.chapter || ' ' || sv.verse) LIKE ?
           OR LOWER(ev.book || ' ' || ev.chapter || ' ' || ev.verse) LIKE ?
      )",
      "%#{query_downcase}%",
      "%#{query_downcase}%",
      reference_pattern,
      reference_pattern,
      reference_pattern,
      reference_pattern
    )
  }

  # Chiasms whose scripture range includes this verse (same book, within start..end).
  scope :containing_verse, ->(verse) {
    joins("INNER JOIN bible_verses AS chiasm_start ON chiasm_start.id = chiasms.start_verse_id")
      .joins("INNER JOIN bible_verses AS chiasm_end ON chiasm_end.id = chiasms.end_verse_id")
      .where("chiasm_start.book = ?", verse.book)
      .where(
        "(chiasm_start.chapter < :c OR (chiasm_start.chapter = :c AND chiasm_start.verse <= :v))",
        c: verse.chapter, v: verse.verse
      )
      .where(
        "(chiasm_end.chapter > :c OR (chiasm_end.chapter = :c AND chiasm_end.verse >= :v))",
        c: verse.chapter, v: verse.verse
      )
  }

  def range_reference
    return start_verse.reference if start_verse_id == end_verse_id
    return "#{start_verse.book} #{start_verse.chapter}:#{start_verse.verse}–#{end_verse.verse}" if start_verse.chapter == end_verse.chapter

    "#{start_verse.reference}–#{end_verse.reference}"
  end

  def passage_verses
    return BibleVerse.none unless start_verse && end_verse

    BibleVerse.where(book: start_verse.book)
              .where(
                "(chapter > :sc OR (chapter = :sc AND verse >= :sv)) AND (chapter < :ec OR (chapter = :ec AND verse <= :ev))",
                sc: start_verse.chapter, sv: start_verse.verse,
                ec: end_verse.chapter, ev: end_verse.verse
              )
              .order(:chapter, :verse)
  end

  # Canonical passage string — must match the limb editor selection surface.
  def passage_text
    passage_verses.map { |v| "#{v.reference} #{v.text}" }.join("\n")
  end

  def limb_count
    chiasm_limbs.size
  end

  def contains_verse?(verse)
    return false unless start_verse && end_verse && verse
    return false unless verse.book == start_verse.book

    after_or_at_start = verse.chapter > start_verse.chapter ||
      (verse.chapter == start_verse.chapter && verse.verse >= start_verse.verse)
    before_or_at_end = verse.chapter < end_verse.chapter ||
      (verse.chapter == end_verse.chapter && verse.verse <= end_verse.verse)

    after_or_at_start && before_or_at_end
  end

  private

  def range_must_be_valid
    return if start_verse.blank? || end_verse.blank?

    if start_verse.book != end_verse.book
      errors.add(:end_verse, "must be in the same book as the start verse")
      return
    end

    start_before_end = start_verse.chapter < end_verse.chapter ||
      (start_verse.chapter == end_verse.chapter && start_verse.verse <= end_verse.verse)

    errors.add(:end_verse, "must be at or after the start verse") unless start_before_end
  end
end
