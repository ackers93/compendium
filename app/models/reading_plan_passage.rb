class ReadingPlanPassage < ApplicationRecord
  belongs_to :reading_plan_day

  validates :slot, presence: true, inclusion: { in: 1..3 }
  validates :position, presence: true
  validates :book, presence: true
  validates :start_chapter, presence: true, numericality: { greater_than: 0 }
  validates :end_chapter, presence: true, numericality: { greater_than: 0 }
  validate :end_chapter_not_before_start
  validate :verse_bounds_consistent

  def chapters
    (start_chapter..end_chapter).to_a
  end

  def verse_bounded?
    start_verse.present? || end_verse.present?
  end

  def bible_chapter_path
    Rails.application.routes.url_helpers.bible_verse_verses_path(book: book, chapter: start_chapter)
  end

  def display_label
    chapter_part =
      if start_chapter == end_chapter
        start_chapter.to_s
      else
        "#{start_chapter}–#{end_chapter}"
      end

    label = "#{book} #{chapter_part}"
    return label unless verse_bounded?

    verse_part =
      if start_verse && end_verse && start_verse != end_verse
        "#{start_verse}–#{end_verse}"
      else
        (start_verse || end_verse).to_s
      end

    "#{book} #{start_chapter}:#{verse_part}"
  end

  private

  def end_chapter_not_before_start
    return if start_chapter.blank? || end_chapter.blank?
    return if end_chapter >= start_chapter

    errors.add(:end_chapter, "must be greater than or equal to start chapter")
  end

  def verse_bounds_consistent
    if start_verse.present? ^ end_verse.present?
      errors.add(:base, "start_verse and end_verse must both be present or both blank")
    end
  end
end
