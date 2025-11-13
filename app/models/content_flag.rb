class ContentFlag < ApplicationRecord
  belongs_to :flaggable, polymorphic: true
  belongs_to :user
  belongs_to :resolved_by, class_name: 'User', optional: true
  
  # Status enum: pending, approved, review_requested, edited, deleted
  enum :status, { 
    pending: 'pending',
    approved: 'approved', 
    review_requested: 'review_requested',
    edited: 'edited',
    deleted: 'deleted'
  }, prefix: true
  
  validates :user_id, presence: true
  validates :flaggable, presence: true
  validates :status, presence: true
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where.not(status: 'pending') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Check if flag is resolved
  def resolved?
    !status_pending?
  end
  
  # Get the flaggable content name for display
  def flaggable_title
    case flaggable_type
    when 'Note'
      flaggable.title
    when 'Comment'
      "Comment on #{flaggable.commentable_type}"
    when 'CrossReference'
      "Cross-reference: #{flaggable.source_verse.reference} → #{flaggable.target_verse.reference}"
    else
      flaggable_type
    end
  end
  
  # Get the author of the flagged content
  def content_author
    flaggable.user
  end
end

