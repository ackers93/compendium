class Comment < ApplicationRecord
  include Flaggable
  include MentionsVerses
  
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :end_verse, class_name: 'BibleVerse', optional: true
  has_many :verse_mentions, as: :mentionable, dependent: :destroy
  has_rich_text :content

  
  validates :content, presence: true
  validate :end_verse_valid
  
  def range?
    end_verse_id.present?
  end
  
  def verse_reference
    return nil unless commentable.is_a?(BibleVerse)
    
    if range?
      "#{commentable.book} #{commentable.chapter}:#{commentable.verse}-#{end_verse.verse}"
    else
      commentable.reference
    end
  end
  
  def involves_verse?(verse)
    return false unless commentable.is_a?(BibleVerse)
    return true if commentable_id == verse.id || end_verse_id == verse.id
    return false unless range?
    
    commentable.book == verse.book &&
      commentable.chapter == verse.chapter &&
      verse.verse.between?(commentable.verse, end_verse.verse)
  end
  
  private
  
  def end_verse_valid
    return if end_verse.nil?
    
    unless commentable.is_a?(BibleVerse)
      errors.add(:end_verse, "can only be set on verse comments")
      return
    end
    
    if end_verse_id == commentable_id
      errors.add(:end_verse, "must be different from the start verse")
    elsif end_verse.book != commentable.book || end_verse.chapter != commentable.chapter
      errors.add(:end_verse, "must be in the same book and chapter as the start verse")
    elsif end_verse.verse <= commentable.verse
      errors.add(:end_verse, "must come after the start verse")
    end
  end
end
