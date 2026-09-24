module MentionsVerses
  extend ActiveSupport::Concern

  VERSE_HREF_PATTERN = %r{/bible_verses/([^/"'\s]+)/(\d+)/(\d+)}
  VERSE_ANCHOR_PATTERN = %r{<a\b[^>]*\bhref=["']/bible_verses/([^/"'\s]+)/(\d+)/(\d+)[^"']*["'][^>]*>(.*?)</a>}mi

  included do
    before_save :autolink_verse_references
    # ActionText touches the parent when the body is saved separately
    after_save :sync_verse_mentions
    after_touch :sync_verse_mentions
  end

  def sync_verse_mentions
    return if destroyed? || !persisted?

    verse_ids = mentioned_bible_verse_ids
    existing = verse_mentions.pluck(:bible_verse_id, :id).to_h

    to_remove = existing.keys - verse_ids
    verse_mentions.where(bible_verse_id: to_remove).delete_all if to_remove.any?

    (verse_ids - existing.keys).each do |verse_id|
      verse_mentions.find_or_create_by!(bible_verse_id: verse_id)
    end
  end

  def mentioned_bible_verse_ids
    html = content&.body&.to_html
    return [] if html.blank?

    ids = Set.new
    ids.merge(verse_ids_from_hrefs(html))
    ids.merge(verse_ids_from_range_link_text(html))
    ids.to_a
  end

  private

  def autolink_verse_references
    return unless content.present?

    html = content.body&.to_html
    return if html.blank?

    new_html = VerseReferenceAutolinker.call(html)
    return if new_html == html

    self.content = new_html
  end

  def verse_ids_from_hrefs(html)
    refs = html.scan(VERSE_HREF_PATTERN).filter_map do |book, chapter, verse|
      decoded = CGI.unescape(book)
      next if decoded.blank?

      [decoded, chapter.to_i, verse.to_i]
    end.uniq

    return [] if refs.empty?

    conditions = refs.map { "(book = ? AND chapter = ? AND verse = ?)" }.join(" OR ")
    BibleVerse.where([conditions, *refs.flatten]).pluck(:id)
  end

  def verse_ids_from_range_link_text(html)
    ids = []

    html.scan(VERSE_ANCHOR_PATTERN) do |_book, _chapter, _verse, link_text|
      plain = Nokogiri::HTML::DocumentFragment.parse(link_text).text.strip
      parsed = VerseReferenceParser.parse(plain)
      next unless parsed&.end_verse

      result = VerseReferenceResolver.call(plain, allow_range: true)
      next if result.error || result.end_verse.nil?

      VerseReferenceResolver.expand_range(result.verse, result.end_verse).each do |verse|
        ids << verse.id
      end
    end

    ids
  end
end
