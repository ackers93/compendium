class Note < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_rich_text :content
  acts_as_taggable_on :tags
  
  validates :title, presence: true
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published] }
  
  # Scopes
  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  
  # Status methods
  def draft?
    status == 'draft'
  end
  
  def published?
    status == 'published'
  end
  
  def publish!
    update(status: 'published')
  end
end