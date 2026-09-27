class CommunityAnswer < ApplicationRecord
  include Flaggable
  include MentionsVerses
  include ValidatesInlineImages

  MAX_DEPTH = 10

  belongs_to :community_question
  belongs_to :user
  belongs_to :parent, class_name: "CommunityAnswer", optional: true, inverse_of: :replies
  has_many :replies, -> { order(created_at: :asc) },
           class_name: "CommunityAnswer",
           foreign_key: :parent_id,
           dependent: :destroy,
           inverse_of: :parent
  has_rich_text :content
  has_many :verse_mentions, as: :mentionable, dependent: :delete_all
  has_many :notifications, as: :notifiable, dependent: :delete_all

  scope :roots, -> { where(parent_id: nil) }

  validates :content, presence: true
  validate :parent_matches_question
  validate :depth_within_limit

  after_create :dispatch_notifications

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

      current = if current.association(:parent).loaded?
        current.parent
      else
        CommunityAnswer.select(:id, :parent_id).find_by(id: current.parent_id)
      end
      break unless current
    end
    @depth = n
  end

  def self.thread_for(question)
    all = question.community_answers
                  .includes(:user, :rich_text_content)
                  .order(created_at: :asc)
                  .to_a
    roots = all.select(&:root?).sort_by(&:created_at).reverse
    children_by_parent = all.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |answer, hash|
      hash[answer.parent_id] << answer if answer.parent_id
    end

    [roots, children_by_parent]
  end

  private

  def dispatch_notifications
    NotificationDispatcher.community_answer_created(self)
  end

  def parent_matches_question
    return if parent.nil?
    return if parent.community_question_id == community_question_id

    errors.add(:parent, "must belong to the same question")
  end

  def depth_within_limit
    return if parent.nil?
    return if parent.depth < MAX_DEPTH

    errors.add(:base, "This thread can't go any deeper")
  end
end
