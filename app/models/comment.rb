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

  IMPORT_SOURCE_OLIVE_TREE = "olive_tree"
  IMPORT_SOURCE_CSV = "csv"
  IMPORT_SOURCES = [IMPORT_SOURCE_OLIVE_TREE, IMPORT_SOURCE_CSV].freeze

  COVERAGE_VERSE = "verse"
  COVERAGE_CHAPTER = "chapter"
  COVERAGE_BOOK = "book"
  COVERAGES = [COVERAGE_VERSE, COVERAGE_CHAPTER, COVERAGE_BOOK].freeze

  scope :roots, -> { where(parent_id: nil) }
  scope :from_import, ->(source) { where(import_source: source) }
  scope :verse_coverage, -> { where(coverage: [COVERAGE_VERSE, nil]) }
  scope :chapter_coverage, -> { where(coverage: COVERAGE_CHAPTER) }
  scope :book_coverage, -> { where(coverage: COVERAGE_BOOK) }

  validates :content, presence: true
  validates :import_source, inclusion: { in: IMPORT_SOURCES }, allow_nil: true
  validates :coverage, inclusion: { in: COVERAGES }
  validate :end_verse_valid
  validate :coverage_allowed
  validate :parent_matches_commentable
  validate :depth_within_limit

  before_validation :normalize_coverage

  after_create :dispatch_notifications

  def olive_tree_import?
    import_source == IMPORT_SOURCE_OLIVE_TREE
  end

  def csv_import?
    import_source == IMPORT_SOURCE_CSV
  end

  def verse_coverage?
    coverage.blank? || coverage == COVERAGE_VERSE
  end

  def chapter_coverage?
    coverage == COVERAGE_CHAPTER
  end

  def book_coverage?
    coverage == COVERAGE_BOOK
  end

  def scoped_coverage?
    chapter_coverage? || book_coverage?
  end

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
    return commentable.book if book_coverage?
    return "#{commentable.book} #{commentable.chapter}" if chapter_coverage?

    if range?
      "#{commentable.book} #{commentable.chapter}:#{commentable.verse}-#{end_verse.verse}"
    else
      commentable.reference
    end
  end

  def involves_verse?(verse)
    return false unless commentable.is_a?(BibleVerse)
    return false if scoped_coverage?
    return true if commentable_id == verse.id || end_verse_id == verse.id
    return false unless range?

    commentable.book == verse.book &&
      commentable.chapter == verse.chapter &&
      verse.verse.between?(commentable.verse, end_verse.verse)
  end

  def self.covering_chapter(book, chapter)
    joins(commentable_verse_join)
      .where(coverage: COVERAGE_CHAPTER, parent_id: nil)
      .where("coverage_verses.book = ? AND coverage_verses.chapter = ?", book, chapter)
  end

  def self.covering_book(book)
    joins(commentable_verse_join)
      .where(coverage: COVERAGE_BOOK, parent_id: nil)
      .where("coverage_verses.book = ?", book)
  end

  def self.thread_children_for(roots)
    return {} if roots.blank?

    commentable_ids = roots.map(&:commentable_id).uniq
    all = where(commentable_type: roots.first.commentable_type, commentable_id: commentable_ids)
            .includes(:user, :end_verse, :commentable, :rich_text_content)
            .order(created_at: :asc)
            .to_a

    all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |comment, hash|
      hash[comment.parent_id] << comment if comment.parent_id
    end
  end

  def self.commentable_verse_join
    "INNER JOIN bible_verses AS coverage_verses ON comments.commentable_type = 'BibleVerse' AND comments.commentable_id = coverage_verses.id"
  end
  private_class_method :commentable_verse_join

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
                   .verse_coverage
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

  def normalize_coverage
    if reply? && parent
      self.coverage = parent.coverage
      self.end_verse = nil
    elsif coverage.blank?
      self.coverage = COVERAGE_VERSE
    end
  end

  def coverage_allowed
    return if verse_coverage?
    return if commentable.is_a?(BibleVerse)

    errors.add(:coverage, "can only be chapter or book for Bible comments")
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

    if scoped_coverage?
      errors.add(:end_verse, "can't be set on chapter or book comments")
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
