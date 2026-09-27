class DiscussionQuestion < ApplicationRecord
  include Flaggable

  QUESTIONABLE_TYPES = %w[BibleVerse Topic].freeze
  BODY_MAX_LENGTH = 1000

  belongs_to :user
  belongs_to :questionable, polymorphic: true

  has_many :notifications, as: :notifiable, dependent: :delete_all

  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }
  validates :questionable_type, inclusion: { in: QUESTIONABLE_TYPES }

  before_validation :strip_body
  after_create :dispatch_notifications

  scope :recent, -> { order(created_at: :desc) }

  scope :search_by_body_or_parent, ->(query) {
    term = query.to_s.strip
    return none if term.blank?

    like = "%#{sanitize_sql_like(term.downcase)}%"
    where(<<~SQL.squish, like: like)
      LOWER(discussion_questions.body) LIKE :like
      OR discussion_questions.id IN (
        SELECT discussion_questions.id
        FROM discussion_questions
        INNER JOIN topics
          ON discussion_questions.questionable_type = 'Topic'
         AND discussion_questions.questionable_id = topics.id
        WHERE LOWER(topics.name) LIKE :like
      )
      OR discussion_questions.id IN (
        SELECT discussion_questions.id
        FROM discussion_questions
        INNER JOIN bible_verses
          ON discussion_questions.questionable_type = 'BibleVerse'
         AND discussion_questions.questionable_id = bible_verses.id
        WHERE LOWER(bible_verses.book) LIKE :like
           OR LOWER(bible_verses.book || ' ' || bible_verses.chapter || ':' || bible_verses.verse) LIKE :like
           OR LOWER(bible_verses.book || ' ' || bible_verses.chapter || ' ' || bible_verses.verse) LIKE :like
      )
    SQL
  }

  def parent_label
    case questionable
    when BibleVerse
      questionable.reference
    when Topic
      questionable.name
    else
      "Unknown"
    end
  end

  private

  def strip_body
    self.body = body.to_s.strip
  end

  def dispatch_notifications
    NotificationDispatcher.discussion_question_created(self)
  end
end
