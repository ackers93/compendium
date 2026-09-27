class CommunityQuestion < ApplicationRecord
  include Flaggable
  include MentionsVerses
  include ValidatesInlineImages

  TITLE_MAX_LENGTH = 200

  belongs_to :user
  has_rich_text :content
  has_many :community_answers, dependent: :destroy
  has_many :topic_items, as: :itemable, dependent: :destroy
  has_many :verse_mentions, as: :mentionable, dependent: :delete_all
  has_many :notifications, as: :notifiable, dependent: :delete_all

  validates :title, presence: true, length: { maximum: TITLE_MAX_LENGTH }
  validates :content, presence: true

  before_validation :strip_title

  scope :recent, -> { order(created_at: :desc) }

  scope :search_by_title_or_body, ->(query) {
    term = query.to_s.strip
    return none if term.blank?

    like = "%#{sanitize_sql_like(term.downcase)}%"
    joins(<<~SQL.squish)
      LEFT JOIN action_text_rich_texts
        ON action_text_rich_texts.record_id = community_questions.id
       AND action_text_rich_texts.record_type = 'CommunityQuestion'
       AND action_text_rich_texts.name = 'content'
    SQL
      .where(
        "LOWER(community_questions.title) LIKE :like OR LOWER(action_text_rich_texts.body) LIKE :like",
        like: like
      )
  }

  private

  def strip_title
    self.title = title.to_s.strip
  end
end
