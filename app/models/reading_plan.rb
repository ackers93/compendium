class ReadingPlan < ApplicationRecord
  BIBLE_COMPANION_SLUG = "bible-companion".freeze

  SLOT_LABELS = {
    1 => "Law and History",
    2 => "Poetry and Prophecy",
    3 => "New Testament"
  }.freeze

  has_many :reading_plan_days, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  def self.bible_companion
    find_by!(slug: BIBLE_COMPANION_SLUG)
  end

  def day_for(date)
    reading_plan_days.includes(:reading_plan_passages).find_by(month: date.month, day: date.day)
  end
end
