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
    @verse_topics = @topic.verse_topics
                         .includes(:bible_verse, :user)
                         .order(created_at: :desc)
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
  
  def set_topic
    @topic = Topic.find(params[:id])
  end
  
  def topic_params
    params.require(:topic).permit(:name)
  end
end

