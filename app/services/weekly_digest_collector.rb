# Aggregates weekly content counts and example links for the digest email.
class WeeklyDigestCollector
  include Rails.application.routes.url_helpers

  EXAMPLES_PER_TYPE = 3
  EXAMPLE_TRUNCATE = 80

  Section = Struct.new(
    :key,
    :label,
    :count,
    :examples,
    :contribute_path,
    keyword_init: true
  )

  Example = Struct.new(:title, :url, :detail, keyword_init: true)

  def self.previous_week_range(now = Time.zone.now)
    week_start = now.beginning_of_week(:monday) - 1.week
    week_start..week_start.end_of_week(:monday)
  end

  def self.call(range: previous_week_range)
    new(range).call
  end

  def initialize(range)
    @range = range
  end

  def call
    [
      notes_section,
      comments_section,
      cross_references_section,
      topics_section,
      bible_threads_section,
      chiasms_section
    ]
  end

  private

  attr_reader :range

  def notes_section
    scope = Note.published.where(created_at: range)
    build_section(
      key: :notes,
      label: "Notes",
      scope: scope,
      contribute_path: new_note_url(**mailer_url_options)
    ) { |note| note_example(note) }
  end

  def comments_section
    scope = Comment.where(created_at: range)
    build_section(
      key: :comments,
      label: "Comments",
      scope: scope,
      contribute_path: bible_verses_books_url(**mailer_url_options),
      includes: [:rich_text_content, :commentable]
    ) { |comment| comment_example(comment) }
  end

  def cross_references_section
    scope = CrossReference.where(created_at: range)
    build_section(
      key: :cross_references,
      label: "Cross-references",
      scope: scope,
      contribute_path: bible_verses_books_url(**mailer_url_options),
      includes: [
        :source_verse,
        :target_verse,
        :target_end_verse,
        { comments: :rich_text_content }
      ]
    ) { |xref| cross_reference_example(xref) }
  end

  def topics_section
    scope = VerseTopic.where(created_at: range)
    build_section(
      key: :topics,
      label: "Topics",
      scope: scope,
      contribute_path: topics_url(**mailer_url_options),
      includes: [:topic, :bible_verse]
    ) { |verse_topic| verse_topic_example(verse_topic) }
  end

  def bible_threads_section
    scope = BibleThread.where(created_at: range)
    build_section(
      key: :bible_threads,
      label: "Threads",
      scope: scope,
      contribute_path: new_bible_thread_url(**mailer_url_options)
    ) { |thread| bible_thread_example(thread) }
  end

  def chiasms_section
    scope = Chiasm.where(created_at: range)
    build_section(
      key: :chiasms,
      label: "Chiasms",
      scope: scope,
      contribute_path: new_chiasm_url(**mailer_url_options)
    ) { |chiasm| chiasm_example(chiasm) }
  end

  def build_section(key:, label:, scope:, contribute_path:, includes: [])
    count = scope.count
    examples = scope.order(created_at: :desc)
                    .includes(includes)
                    .limit(EXAMPLES_PER_TYPE)
                    .map { |record| yield(record) }

    Section.new(
      key: key,
      label: label,
      count: count,
      examples: examples,
      contribute_path: contribute_path
    )
  end

  def note_example(note)
    Example.new(title: note.title, url: note_url(note, **mailer_url_options))
  end

  def comment_example(comment)
    plain = comment.content.to_plain_text.to_s.squish
    snippet = plain.presence&.truncate(EXAMPLE_TRUNCATE) || "Comment"
    context = comment_context(comment)
    title = context.present? ? "#{snippet} (#{context})" : snippet
    Example.new(title: title, url: comment_url_for(comment))
  end

  def cross_reference_example(xref)
    source = xref.source_verse
    comment_snippets = xref.comments.filter_map do |comment|
      comment.content.to_plain_text.to_s.squish.presence&.truncate(EXAMPLE_TRUNCATE)
    end

    Example.new(
      title: xref.connection_label,
      url: bible_verse_show_url(
        book: source.book,
        chapter: source.chapter,
        verse: source.verse,
        **mailer_url_options
      ),
      detail: comment_snippets.presence&.join(" · ")
    )
  end

  def verse_topic_example(verse_topic)
    Example.new(
      title: "#{verse_topic.topic.name} — #{verse_topic.bible_verse.reference}",
      url: topic_url(verse_topic.topic, **mailer_url_options)
    )
  end

  def bible_thread_example(thread)
    Example.new(title: thread.title, url: bible_thread_url(thread, **mailer_url_options))
  end

  def chiasm_example(chiasm)
    Example.new(title: chiasm.title, url: chiasm_url(chiasm, **mailer_url_options))
  end

  def comment_context(comment)
    case comment.commentable
    when Note
      "on note: #{comment.commentable.title}"
    when BibleVerse
      "on #{comment.verse_reference || comment.commentable.reference}"
    when CrossReference
      "on cross-reference: #{comment.commentable.connection_label}"
    else
      nil
    end
  end

  def comment_url_for(comment)
    case comment.commentable
    when Note
      note_url(comment.commentable, **mailer_url_options)
    when BibleVerse
      verse = comment.commentable
      bible_verse_show_url(book: verse.book, chapter: verse.chapter, verse: verse.verse, **mailer_url_options)
    when CrossReference
      source = comment.commentable.source_verse
      bible_verse_show_url(book: source.book, chapter: source.chapter, verse: source.verse, **mailer_url_options)
    else
      root_url(**mailer_url_options)
    end
  end

  def mailer_url_options
    opts = ActionMailer::Base.default_url_options.presence ||
           Rails.application.config.action_mailer.default_url_options.presence ||
           { host: "localhost", port: 3000 }
    opts.to_h.symbolize_keys
  end
end
