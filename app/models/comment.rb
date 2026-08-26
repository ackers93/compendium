class Comment < ApplicationRecord
  include Flaggable
  include MentionsVerses
  include ValidatesInlineImages

  MAX_DEPTH = 10

  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :end_verse, class_name: 'BibleVerse', optional: true
  belongs_to :parent, class_name: 'Comment', optional: true, inverse_of: :replies
  has_many :replies, -> { order(created_at: :asc) },
           class_name: 'Comment',
           foreign_key: :parent_id,
           dependent: :destroy,
           inverse_of: :parent
  has_many :verse_mentions, as: :mentionable, dependent: :destroy
  has_many :topic_items, as: :itemable, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :delete_all
  has_rich_text :content

  scope :roots, -> { where(parent_id: nil) }

  validates :content, presence: true
  validate :end_verse_valid
  validate :parent_matches_commentable
  validate :depth_within_limit

  after_create :dispatch_notifications

  def range?
    end_verse_id.present?
  end

  def root?
    parent_id.nil?
  end

  def reply?
    parent_id.present?
  end

  def depth
    return @depth if defined?(@depth)

    n = 0
    current = self
    while current.parent_id
      n += 1
      break if n > MAX_DEPTH
      current = current.association(:parent).loaded? ? current.parent : Comment.select(:id, :parent_id).find_by(id: current.parent_id)
      break unless current
    end
    @depth = n
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

  # Returns [roots, children_by_parent_id] for threaded rendering.
  # For bible verses, roots are visible on that verse; replies are loaded from
  # the same commentable records so range-comment threads stay intact.
  def self.thread_for(commentable)
    if commentable.is_a?(BibleVerse)
      roots = commentable.visible_comments.roots
                        .includes(:user, :end_verse, :commentable, :rich_text_content)
                        .order(created_at: :desc)
                        .to_a
      return [[], {}] if roots.empty?

      commentable_ids = roots.map(&:commentable_id).uniq
      all = Comment.where(commentable_type: 'BibleVerse', commentable_id: commentable_ids)
                   .includes(:user, :end_verse, :commentable, :rich_text_content)
                   .order(created_at: :asc)
                   .to_a
    else
      all = commentable.comments
                       .includes(:user, :rich_text_content)
                       .order(created_at: :asc)
                       .to_a
      roots = all.select(&:root?).sort_by(&:created_at).reverse
    end

    children_by_parent = all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |comment, hash|
      hash[comment.parent_id] << comment if comment.parent_id
    end

    [roots, children_by_parent]
  end

  private

  def dispatch_notifications
    NotificationDispatcher.comment_created(self)
  end

  def parent_matches_commentable
    return if parent.nil?

    if parent.commentable_type != commentable_type || parent.commentable_id != commentable_id
      errors.add(:parent, "must belong to the same record")
    end
  end

  def depth_within_limit
    return if parent.nil?

    if parent.depth >= MAX_DEPTH
      errors.add(:base, "This thread can't go any deeper")
    end
  end

  def end_verse_valid
    return if end_verse.nil?

    if reply?
      errors.add(:end_verse, "can't be set on replies")
      return
    end

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
