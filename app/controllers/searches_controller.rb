class SearchesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Main search page - no data needed here, topics will load via turbo frame
  end
  
  def topics
    # Search topics endpoint for turbo frame
    @topics = Topic.includes(verse_topics: :bible_verse)
                   .left_joins(:verse_topics)
    
    # Apply search filter if query parameter is present
    if params[:q].present?
      @topics = @topics.search_by_name_or_verses(params[:q])
    end
    
    @topics = @topics.group('topics.id')
                     .order('COUNT(verse_topics.id) DESC, topics.name ASC')
                     .select('topics.*, COUNT(verse_topics.id) as verses_count')
    
    render partial: 'topics_results'
  end
  
  def threads
    # Search threads endpoint for turbo frame
    @bible_threads = BibleThread.includes(:user, bible_thread_entries: :bible_verse)
    
    # Apply search filter if query parameter is present
    if params[:q].present?
      @bible_threads = @bible_threads.search_by_title_or_verses(params[:q])
    end
    
    @bible_threads = @bible_threads.order(created_at: :desc)
    
    render partial: 'threads_results'
  end
  
  def notes
    # Search notes endpoint for turbo frame
    @query = params[:q].to_s.strip
    
    if @query.present?
      query_downcase = @query.downcase
      # Search by title, tags, and content
      @notes = Note.published
                   .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = notes.id AND action_text_rich_texts.record_type = 'Note' AND action_text_rich_texts.name = 'content'")
                   .joins("LEFT JOIN taggings ON taggings.taggable_id = notes.id AND taggings.taggable_type = 'Note'")
                   .joins("LEFT JOIN tags ON tags.id = taggings.tag_id")
                   .where("LOWER(notes.title) LIKE ? OR LOWER(action_text_rich_texts.body) LIKE ? OR LOWER(tags.name) LIKE ?",
                          "%#{query_downcase}%", "%#{query_downcase}%", "%#{query_downcase}%")
                   .includes(:user, :rich_text_content)
                   .distinct
                   .order(created_at: :desc)
    else
      @notes = Note.published.includes(:user, :rich_text_content).order(created_at: :desc)
    end
    
    render partial: 'notes_results'
  end
end
