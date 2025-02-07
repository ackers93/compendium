class BibleVerse < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
  
  validates :book, presence: true
  validates :chapter, presence: true
  validates :verse, presence: true
  validates :text, presence: true
  validates :testament, presence: true, inclusion: { in: ['OT', 'NT'] }

end