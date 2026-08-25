class ReadingPlanDay < ApplicationRecord
  belongs_to :reading_plan
  has_many :reading_plan_passages, -> { order(:slot, :position) }, dependent: :destroy

  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :day, presence: true, inclusion: { in: 1..31 }
  validates :day, uniqueness: { scope: [:reading_plan_id, :month] }

  def passages_by_slot
    reading_plan_passages.group_by(&:slot)
  end
end
