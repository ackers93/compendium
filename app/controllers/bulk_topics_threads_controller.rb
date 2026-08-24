class BulkTopicsThreadsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :authorize_create!

  VALID_KINDS = %w[topic thread].freeze

  def new
    @kind = selected_kind
    @title = params[:title].to_s
    @verse_refs = params[:verse_refs].to_s
    @errors = []
  end

  def create
    @kind = selected_kind
    @title = params[:title].to_s.strip
    @verse_refs = params[:verse_refs].to_s
    @errors = []

    if @title.blank?
      @errors << "Title is required."
      render :new, status: :unprocessable_entity
      return
    end

    parsed = VerseReferenceResolver.parse_list(@verse_refs)
    @errors.concat(parsed.errors)

    if parsed.verses.empty?
      @errors << "Add at least one valid verse reference." if @errors.empty?
      render :new, status: :unprocessable_entity
      return
    end

    if @errors.any?
      render :new, status: :unprocessable_entity
      return
    end

    if @kind == "topic"
      create_topic(parsed.verses)
    else
      create_thread(parsed.verses)
    end
  end

  private

  def selected_kind
    kind = params[:kind].to_s
    VALID_KINDS.include?(kind) ? kind : "topic"
  end

  def create_topic(verses)
    topic = Topic.find_or_create_by_name(@title)

    unless topic.persisted?
      @errors = topic.errors.full_messages
      render :new, status: :unprocessable_entity
      return
    end

    verses.each do |verse|
      VerseTopic.find_or_create_by!(topic: topic, bible_verse: verse, user: current_user)
    end

    redirect_to topic_path(topic),
                notice: "#{verses.size} #{'verse'.pluralize(verses.size)} added to \"#{topic.name}\". Add an explanation for each verse below."
  end

  def create_thread(verses)
    thread = BibleThread.new(title: @title, user: current_user)

    verses.each_with_index do |verse, index|
      thread.bible_thread_entries.build(bible_verse: verse, position: index + 1)
    end

    if thread.save
      redirect_to edit_bible_thread_path(thread),
                  notice: "Thread created with #{verses.size} #{'verse'.pluralize(verses.size)}. Add commentary to each verse below."
    else
      @errors = thread.errors.full_messages
      render :new, status: :unprocessable_entity
    end
  end
end
