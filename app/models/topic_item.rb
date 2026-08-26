class TopicItem < ApplicationRecord
  include Flaggable

  ITEMABLE_TYPES = %w[Note BibleThread Chiasm Comment CrossReference].freeze

  TYPE_LABELS = {
    "Note" => "Notes",
    "BibleThread" => "Threads",
    "Chiasm" => "Chiasms",
    "Comment" => "Comments",
    "CrossReference" => "Cross-references"
  }.freeze

  belongs_to :topic
  belongs_to :user
  belongs_to :itemable, polymorphic: true

  has_rich_text :note
  has_many :notifications, as: :notifiable, dependent: :delete_all

  attr_accessor :topic_name

  validates :itemable_type, inclusion: { in: ITEMABLE_TYPES }
  validates :itemable_id, uniqueness: {
    scope: [:topic_id, :itemable_type, :user_id],
    message: "You have already pinned this to this topic"
  }
  validate :itemable_must_be_pinnable

  after_create :dispatch_notifications

  def visible_to?(viewer)
    return true unless itemable.is_a?(Note)
    return true if itemable.published?
    return false unless viewer

    viewer.id == itemable.user_id || viewer.role_admin?
  end

  def type_label
    TYPE_LABELS[itemable_type] || itemable_type
  end

  def itemable_title
    case itemable
    when Note
      itemable.title
    when BibleThread
      itemable.title
    when Chiasm
      itemable.title
    when Comment
      plain = itemable.content.to_plain_text.to_s.strip
      plain.present? ? plain.truncate(80) : "Comment"
    when CrossReference
      itemable.connection_label
    else
      itemable_type
    end
  end

  private

  def itemable_must_be_pinnable
    return if itemable.blank?

    unless ITEMABLE_TYPES.include?(itemable.class.name)
      errors.add(:itemable, "is not a pinnable content type")
      return
    end

    if itemable.is_a?(Note) && itemable.draft?
      errors.add(:itemable, "must be published before pinning to a topic")
    end
  end

  def dispatch_notifications
    NotificationDispatcher.topic_item_created(self)
  end
end
