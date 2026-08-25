class BulkTopicsThreadsController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  VALID_KINDS = %w[topic thread].freeze

  def new
    kind = selected_kind
    redirect_to bulk_upload_hub_path(tab: kind == "thread" ? "threads" : "topics")
  end

  def create
    @kind = selected_kind
    title = params[:title].to_s.strip
    verse_refs = params[:verse_refs].to_s
    errors = []

    if title.blank?
      errors << "Title is required."
      assign_topic_thread_fields(title, verse_refs, errors)
      render_bulk_upload_hub(active_tab: active_tab_for_kind)
      return
    end

    parsed = VerseReferenceResolver.parse_list(verse_refs)
    errors.concat(parsed.errors)

    if parsed.verses.empty?
      errors << "Add at least one valid verse reference." if errors.empty?
      assign_topic_thread_fields(title, verse_refs, errors)
      render_bulk_upload_hub(active_tab: active_tab_for_kind)
      return
    end

    if errors.any?
      assign_topic_thread_fields(title, verse_refs, errors)
      render_bulk_upload_hub(active_tab: active_tab_for_kind)
      return
    end

    if @kind == "topic"
      create_topic(title, verse_refs, parsed.verses)
    else
      create_thread(title, verse_refs, parsed.verses)
    end
  end

  private

  def selected_kind
    kind = params[:kind].to_s
    VALID_KINDS.include?(kind) ? kind : "topic"
  end

  def active_tab_for_kind
    @kind == "thread" ? "threads" : "topics"
  end

  def assign_topic_thread_fields(title, verse_refs, errors)
    if @kind == "thread"
      @thread_title = title
      @thread_verse_refs = verse_refs
      @thread_errors = errors
    else
      @topic_title = title
      @topic_verse_refs = verse_refs
      @topic_errors = errors
    end
  end

  def create_topic(title, verse_refs, verses)
    topic = Topic.find_or_create_by_name(title)

    unless topic.persisted?
      assign_topic_thread_fields(title, verse_refs, topic.errors.full_messages)
      render_bulk_upload_hub(active_tab: "topics")
      return
    end

    verses.each do |verse|
      VerseTopic.find_or_create_by!(topic: topic, bible_verse: verse, user: current_user)
    end

    redirect_to topic_path(topic),
                notice: "#{verses.size} #{'verse'.pluralize(verses.size)} added to \"#{topic.name}\". Add an explanation for each verse below."
  end

  def create_thread(title, verse_refs, verses)
    thread = BibleThread.new(title: title, user: current_user)
    thread.current_editor = current_user

    verses.each_with_index do |verse, index|
      thread.bible_thread_entries.build(bible_verse: verse, position: index + 1)
    end

    if thread.save
      redirect_to edit_bible_thread_path(thread),
                  notice: "Thread created with #{verses.size} #{'verse'.pluralize(verses.size)}. Add commentary to each verse below."
    else
      assign_topic_thread_fields(title, verse_refs, thread.errors.full_messages)
      render_bulk_upload_hub(active_tab: "threads")
    end
  end
end
