# Builds a typed node/edge graph of connected study content for the Map view.
# Pass include_node_types to omit types (e.g. Comment) without changing callers.
class GraphMapBuilder
  include Rails.application.routes.url_helpers

  NODE_TYPES = %w[BibleVerse Topic Note BibleThread Chiasm CrossReference Comment].freeze

  TYPE_LABELS = {
    "BibleVerse" => "Verses",
    "Topic" => "Topics",
    "Note" => "Notes",
    "BibleThread" => "Threads",
    "Chiasm" => "Chiasms",
    "CrossReference" => "Cross-references",
    "Comment" => "Comments"
  }.freeze

  MIN_NODE_SIZE = 4
  MAX_NODE_SIZE = 18

  def self.call(viewer:, include_node_types: NODE_TYPES)
    new(viewer: viewer, include_node_types: include_node_types).call
  end

  def initialize(viewer:, include_node_types: NODE_TYPES)
    @viewer = viewer
    @include_node_types = Array(include_node_types).map(&:to_s) & NODE_TYPES
    @nodes = {}
    @edges = []
    @edge_keys = {}
    @pending_labels = Hash.new { |h, k| h[k] = Set.new }
  end

  def call
    add_verse_topics
    add_topic_items
    add_thread_entries
    add_cross_references
    add_chiasms
    add_comments
    add_mentions
    hydrate_labels
    finalize
  end

  private

  attr_reader :viewer, :include_node_types

  def include_type?(type)
    include_node_types.include?(type)
  end

  def node_id(type, id)
    "#{type}:#{id}"
  end

  def register_node(type, id)
    return nil unless include_type?(type) && id.present?

    key = node_id(type, id)
    unless @nodes.key?(key)
      @nodes[key] = { id: key, type: type, label: nil, url: nil }
      @pending_labels[type] << id
    end
    key
  end

  def add_edge(edge_type, source_key, target_key)
    return if source_key.blank? || target_key.blank? || source_key == target_key

    a, b = [source_key, target_key].minmax
    dedupe = "#{edge_type}|#{a}|#{b}"
    return if @edge_keys[dedupe]

    @edge_keys[dedupe] = true
    @edges << { id: dedupe, source: source_key, target: target_key, type: edge_type }
  end

  def add_verse_topics
    return unless include_type?("BibleVerse") && include_type?("Topic")

    VerseTopic.pluck(:bible_verse_id, :topic_id).each do |verse_id, topic_id|
      v = register_node("BibleVerse", verse_id)
      t = register_node("Topic", topic_id)
      add_edge("verse_topic", v, t)
    end
  end

  def add_topic_items
    return unless include_type?("Topic")

    TopicItem.pluck(:topic_id, :itemable_type, :itemable_id).each do |topic_id, itemable_type, itemable_id|
      next unless include_type?(itemable_type)
      next if itemable_type == "Note" && !note_visible?(itemable_id)

      topic_key = register_node("Topic", topic_id)
      item_key = register_node(itemable_type, itemable_id)
      add_edge("topic_item", topic_key, item_key)
    end
  end

  def add_thread_entries
    return unless include_type?("BibleVerse") && include_type?("BibleThread")

    BibleThreadEntry.pluck(:bible_verse_id, :bible_thread_id).each do |verse_id, thread_id|
      v = register_node("BibleVerse", verse_id)
      t = register_node("BibleThread", thread_id)
      add_edge("thread_entry", v, t)
    end
  end

  def add_cross_references
    return unless include_type?("BibleVerse")

    CrossReference.pluck(:id, :source_verse_id, :target_verse_id).each do |id, source_id, target_id|
      source_key = register_node("BibleVerse", source_id)
      target_key = register_node("BibleVerse", target_id)
      add_edge("cross_reference", source_key, target_key)

      next unless include_type?("CrossReference")

      cr_key = register_node("CrossReference", id)
      add_edge("cross_reference", cr_key, source_key)
      add_edge("cross_reference", cr_key, target_key)
    end
  end

  def add_chiasms
    return unless include_type?("Chiasm") && include_type?("BibleVerse")

    Chiasm.pluck(:id, :start_verse_id, :end_verse_id).each do |id, start_id, end_id|
      chiasm_key = register_node("Chiasm", id)
      start_key = register_node("BibleVerse", start_id)
      end_key = register_node("BibleVerse", end_id)
      add_edge("chiasm_range", chiasm_key, start_key)
      add_edge("chiasm_range", chiasm_key, end_key) if start_id != end_id
    end
  end

  def add_comments
    return unless include_type?("Comment")

    Comment.pluck(:id, :commentable_type, :commentable_id, :parent_id).each do |id, ctype, cid, parent_id|
      next unless %w[BibleVerse Note CrossReference].include?(ctype)
      next unless include_type?(ctype)
      next if ctype == "Note" && !note_visible?(cid)

      comment_key = register_node("Comment", id)
      parent_content_key = register_node(ctype, cid)
      add_edge("comment", comment_key, parent_content_key)

      next if parent_id.blank?

      parent_comment_key = register_node("Comment", parent_id)
      add_edge("comment", comment_key, parent_comment_key)
    end
  end

  def add_mentions
    return unless include_type?("BibleVerse")

    VerseMention.pluck(:bible_verse_id, :mentionable_type, :mentionable_id).each do |verse_id, mtype, mid|
      next unless %w[Note Comment].include?(mtype)
      next unless include_type?(mtype)

      if mtype == "Note"
        next unless note_visible?(mid)
      elsif mtype == "Comment"
        next unless comment_mention_visible?(mid)
      end

      verse_key = register_node("BibleVerse", verse_id)
      mentionable_key = register_node(mtype, mid)
      add_edge("mention", mentionable_key, verse_key)
    end
  end

  def note_visible?(note_id)
    @visible_note_ids ||= begin
      scope = Note.where(status: "published")
      if viewer
        if viewer.role_admin?
          scope = Note.all
        else
          scope = Note.where(status: "published").or(Note.where(user_id: viewer.id))
        end
      end
      scope.pluck(:id).to_set
    end
    @visible_note_ids.include?(note_id)
  end

  def comment_mention_visible?(comment_id)
    @comment_note_parents ||= Comment.where(commentable_type: "Note")
                                     .pluck(:id, :commentable_id)
                                     .to_h
    note_id = @comment_note_parents[comment_id]
    return true if note_id.nil?

    note_visible?(note_id)
  end

  def hydrate_labels
    hydrate_verses
    hydrate_topics
    hydrate_notes
    hydrate_threads
    hydrate_chiasms
    hydrate_cross_references
    hydrate_comments
  end

  def hydrate_verses
    ids = @pending_labels["BibleVerse"].to_a
    return if ids.empty?

    BibleVerse.where(id: ids).pluck(:id, :book, :chapter, :verse).each do |id, book, chapter, verse|
      key = node_id("BibleVerse", id)
      @nodes[key][:label] = "#{book} #{chapter}:#{verse}"
      @nodes[key][:url] = bible_verse_show_path(book: book, chapter: chapter, verse: verse)
    end
  end

  def hydrate_topics
    ids = @pending_labels["Topic"].to_a
    return if ids.empty?

    Topic.where(id: ids).pluck(:id, :name).each do |id, name|
      key = node_id("Topic", id)
      @nodes[key][:label] = name
      @nodes[key][:url] = topic_path(id)
    end
  end

  def hydrate_notes
    ids = @pending_labels["Note"].to_a
    return if ids.empty?

    Note.where(id: ids).pluck(:id, :title).each do |id, title|
      key = node_id("Note", id)
      @nodes[key][:label] = title
      @nodes[key][:url] = note_path(id)
    end
  end

  def hydrate_threads
    ids = @pending_labels["BibleThread"].to_a
    return if ids.empty?

    BibleThread.where(id: ids).pluck(:id, :title).each do |id, title|
      key = node_id("BibleThread", id)
      @nodes[key][:label] = title
      @nodes[key][:url] = bible_thread_path(id)
    end
  end

  def hydrate_chiasms
    ids = @pending_labels["Chiasm"].to_a
    return if ids.empty?

    Chiasm.where(id: ids).pluck(:id, :title).each do |id, title|
      key = node_id("Chiasm", id)
      @nodes[key][:label] = title
      @nodes[key][:url] = chiasm_path(id)
    end
  end

  def hydrate_cross_references
    ids = @pending_labels["CrossReference"].to_a
    return if ids.empty?

    CrossReference.where(id: ids).includes(:source_verse, :target_verse, :target_end_verse).find_each do |xref|
      key = node_id("CrossReference", xref.id)
      @nodes[key][:label] = xref.connection_label
      source = xref.source_verse
      @nodes[key][:url] = bible_verse_show_path(
        book: source.book,
        chapter: source.chapter,
        verse: source.verse
      )
    end
  end

  def hydrate_comments
    ids = @pending_labels["Comment"].to_a
    return if ids.empty?

    comments = Comment.where(id: ids).includes(:rich_text_content, :commentable)
    comments.find_each do |comment|
      key = node_id("Comment", comment.id)
      plain = comment.content.to_plain_text.to_s.squish
      @nodes[key][:label] = plain.present? ? plain.truncate(40) : "Comment"
      @nodes[key][:url] = comment_url_for(comment)
    end
  end

  def comment_url_for(comment)
    case comment.commentable
    when Note
      note_path(comment.commentable)
    when BibleVerse
      verse = comment.commentable
      bible_verse_show_path(book: verse.book, chapter: verse.chapter, verse: verse.verse)
    when CrossReference
      source = comment.commentable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    else
      root_path
    end
  end

  def finalize
    degrees = Hash.new(0)
    @edges.each do |edge|
      degrees[edge[:source]] += 1
      degrees[edge[:target]] += 1
    end

    connected_ids = degrees.keys.to_set
    nodes = @nodes.values.select { |node| connected_ids.include?(node[:id]) }
    max_degree = degrees.values.max || 1

    nodes.each do |node|
      degree = degrees[node[:id]]
      node[:degree] = degree
      node[:size] = sized(degree, max_degree)
      node[:label] ||= node[:id]
    end

    node_ids = nodes.map { |n| n[:id] }.to_set
    edges = @edges.select { |e| node_ids.include?(e[:source]) && node_ids.include?(e[:target]) }

    {
      nodes: nodes,
      edges: edges,
      types: include_node_types.map { |type|
        { id: type, label: TYPE_LABELS[type] || type }
      }
    }
  end

  def sized(degree, max_degree)
    return MIN_NODE_SIZE if max_degree <= 1

    ratio = Math.sqrt(degree.to_f / max_degree)
    (MIN_NODE_SIZE + (MAX_NODE_SIZE - MIN_NODE_SIZE) * ratio).round(1)
  end
end
