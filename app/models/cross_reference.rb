class CrossReference < ApplicationRecord
  belongs_to :source_verse, class_name: 'BibleVerse'
  belongs_to :target_verse, class_name: 'BibleVerse'
  has_many :comments, as: :commentable, dependent: :destroy
  
  validates :source_verse_id, presence: true
  validates :target_verse_id, presence: true
  validate :source_and_target_different
  
  private
  
  def source_and_target_different
    if source_verse_id == target_verse_id
      errors.add(:base, "Source and target verses must be different")
    end
  end
end
