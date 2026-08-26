class CrossReference < ApplicationRecord
  include Flaggable
  
  belongs_to :source_verse, class_name: 'BibleVerse'
  belongs_to :target_verse, class_name: 'BibleVerse'
  belongs_to :target_end_verse, class_name: 'BibleVerse', optional: true
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :topic_items, as: :itemable, dependent: :destroy
  
  validates :source_verse_id, presence: true
  validates :target_verse_id, presence: true
  validate :source_and_target_different
  validate :target_end_verse_valid
  
  def range?
    target_end_verse_id.present?
  end
  
  def target_reference
    if range?
      "#{target_verse.book} #{target_verse.chapter}:#{target_verse.verse}-#{target_end_verse.verse}"
    else
      target_verse.reference
    end
  end
  
  def connection_label
    "#{source_verse.reference} → #{target_reference}"
  end
  
  # Reference shown on the "other" side relative to the given verse
  def display_reference_for(verse)
    source_verse_id == verse.id ? target_reference : source_verse.reference
  end
  
  # Verse used for linking (start of range when viewing from source)
  def link_verse_for(verse)
    source_verse_id == verse.id ? target_verse : source_verse
  end
  
  def preview_text_for(verse)
    link_verse_for(verse).text
  end
  
  def involves_verse?(verse)
    return true if source_verse_id == verse.id || target_verse_id == verse.id || target_end_verse_id == verse.id
    return false unless range?
    
    target_verse.book == verse.book &&
      target_verse.chapter == verse.chapter &&
      verse.verse.between?(target_verse.verse, target_end_verse.verse)
  end
  
  private
  
  def source_and_target_different
    if source_verse_id == target_verse_id || source_verse_id == target_end_verse_id
      errors.add(:base, "Source and target verses must be different")
      return
    end
    
    return unless range? && source_verse && target_verse && target_end_verse
    
    if source_verse.book == target_verse.book &&
       source_verse.chapter == target_verse.chapter &&
       source_verse.verse.between?(target_verse.verse, target_end_verse.verse)
      errors.add(:base, "Source verse cannot be within the target range")
    end
  end
  
  def target_end_verse_valid
    return if target_end_verse.nil? || target_verse.nil?
    
    if target_end_verse_id == target_verse_id
      errors.add(:target_end_verse, "must be different from the start verse")
    elsif target_end_verse.book != target_verse.book || target_end_verse.chapter != target_verse.chapter
      errors.add(:target_end_verse, "must be in the same book and chapter as the start verse")
    elsif target_end_verse.verse <= target_verse.verse
      errors.add(:target_end_verse, "must come after the start verse")
    end
  end
end
