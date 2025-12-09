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
end
