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
end

