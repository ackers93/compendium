class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic, only: [:show]
  
  def index
    @topics = Topic.includes(verse_topics: :bible_verse)
                   .left_joins(:verse_topics)
                   .group('topics.id')
                   .order('COUNT(verse_topics.id) DESC, topics.name ASC')
                   .select('topics.*, COUNT(verse_topics.id) as verses_count')
  end
  
  def show
    verse_topics = @topic.verse_topics
                         .includes(:bible_verse, :user)
                         .order('bible_verses.book ASC, bible_verses.chapter ASC, bible_verses.verse ASC')
    @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
  end
  
  # Autocomplete endpoint for topic search
  def autocomplete
    query = params[:q].to_s.strip
    
    if query.present?
      topics = Topic.search_by_name(query).limit(10)
      render json: topics.map { |topic| { id: topic.id, name: topic.name } }
    else
      render json: []
    end
  end
  
  # Create a new topic
  def create
    @topic = Topic.find_or_create_by(name: topic_params[:name])
    
    if @topic.persisted?
      render json: { id: @topic.id, name: @topic.name }, status: :created
    else
      render json: { errors: @topic.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def group_consecutive_verses(verse_topics)
    return [] if verse_topics.empty?
    
    groups = []
    current_group = [verse_topics.first]
    
    verse_topics.each_cons(2) do |prev, curr|
      prev_verse = prev.bible_verse
      curr_verse = curr.bible_verse
      
      # Check if verses are consecutive (same book, same chapter, verse number is +1)
      if prev_verse.book == curr_verse.book && 
         prev_verse.chapter == curr_verse.chapter && 
         curr_verse.verse == prev_verse.verse + 1
        current_group << curr
      else
        groups << current_group
        current_group = [curr]
      end
    end
    
    groups << current_group
    groups
  end
  
  def set_topic
    @topic = Topic.find(params[:id])
  end
  
  def topic_params
    params.require(:topic).permit(:name)
  end
end

