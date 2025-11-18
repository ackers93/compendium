class BibleThreadEntry < ApplicationRecord
  belongs_to :bible_thread
  belongs_to :bible_verse
  
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :bible_verse_id, uniqueness: { scope: :bible_thread_id, message: "is already in this thread" }
  
  # Automatically set position if not set
  before_validation :set_position, on: :create, if: -> { bible_thread.present? }
  
  private
  
  def set_position
    if position.nil?
      max_position = bible_thread.bible_thread_entries.maximum(:position) || 0
      self.position = max_position + 1
    end
  end
end

