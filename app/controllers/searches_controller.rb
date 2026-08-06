class SearchesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Main search page - no data needed here, topics will load via turbo frame
  end
  
  def topics
    # Search topics endpoint for turbo frame
    if params[:q].present?
      @topics = Topic.includes(verse_topics: :bible_verse)
                     .left_joins(:verse_topics)
                     .search_by_name_or_verses(params[:q])
                     .group('topics.id')
                     .order('COUNT(verse_topics.id) DESC, topics.name ASC')
                     .select('topics.*, COUNT(verse_topics.id) as verses_count')
    else
      @topics = Topic.none
    end
    
    render partial: 'topics_results'
  end
  
  def threads
    # Search threads endpoint for turbo frame
    if params[:q].present?
      @bible_threads = BibleThread.includes(:user, bible_thread_entries: :bible_verse)
                                  .search_by_title_or_verses(params[:q])
                                  .order(created_at: :desc)
    else
      @bible_threads = BibleThread.none
    end
    
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
      @notes = Note.none
    end
    
    render partial: 'notes_results'
  end
  
  def verse_comments
    # Search comments on verses endpoint for turbo frame
    @query = params[:q].to_s.strip
    
    if @query.present?
      query_downcase = @query.downcase
      @comments = Comment.includes(:user, :rich_text_content, :commentable)
                         .where(commentable_type: 'BibleVerse')
                         .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = comments.id AND action_text_rich_texts.record_type = 'Comment' AND action_text_rich_texts.name = 'content'")
                         .where("LOWER(action_text_rich_texts.body) LIKE ?", "%#{query_downcase}%")
                         .order(created_at: :desc)
    else
      @comments = Comment.none
    end
    
    render partial: 'verse_comments_results'
  end
  
  def cross_reference_comments
    # Search comments on cross references endpoint for turbo frame
    @query = params[:q].to_s.strip
    
    if @query.present?
      query_downcase = @query.downcase
      @comments = Comment.includes(:user, :rich_text_content, commentable: [:source_verse, :target_verse])
                         .where(commentable_type: 'CrossReference')
                         .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = comments.id AND action_text_rich_texts.record_type = 'Comment' AND action_text_rich_texts.name = 'content'")
                         .where("LOWER(action_text_rich_texts.body) LIKE ?", "%#{query_downcase}%")
                         .order(created_at: :desc)
    else
      @comments = Comment.none
    end
    
    render partial: 'cross_reference_comments_results'
  end
  
  def note_comments
    # Search comments on notes endpoint for turbo frame
    @query = params[:q].to_s.strip
    
    if @query.present?
      query_downcase = @query.downcase
      @comments = Comment.includes(:user, :rich_text_content, :commentable)
                         .where(commentable_type: 'Note')
                         .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = comments.id AND action_text_rich_texts.record_type = 'Comment' AND action_text_rich_texts.name = 'content'")
                         .where("LOWER(action_text_rich_texts.body) LIKE ?", "%#{query_downcase}%")
                         .order(created_at: :desc)
    else
      @comments = Comment.none
    end
    
    render partial: 'note_comments_results'
  end
end
