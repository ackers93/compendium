module MentionsVerses
  extend ActiveSupport::Concern

  VERSE_HREF_PATTERN = %r{/bible_verses/([^/"'\s]+)/(\d+)/(\d+)}

  included do
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

    refs = html.scan(VERSE_HREF_PATTERN).filter_map do |book, chapter, verse|
      decoded = CGI.unescape(book)
      next if decoded.blank?

      [decoded, chapter.to_i, verse.to_i]
    end.uniq

    return [] if refs.empty?

    conditions = refs.map { "(book = ? AND chapter = ? AND verse = ?)" }.join(" OR ")
    BibleVerse.where([conditions, *refs.flatten]).pluck(:id)
  end
end
