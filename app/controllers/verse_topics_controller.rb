class VerseTopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bible_verse
  
  def new
    @verse_topic = VerseTopic.new(bible_verse: @bible_verse)
  end
  
  def create
    topic_name = params[:verse_topic][:topic_name].to_s.strip
    
    if topic_name.blank?
      @verse_topic = VerseTopic.new(bible_verse: @bible_verse)
      @verse_topic.errors.add(:topic_name, "can't be blank")
      render :new, status: :unprocessable_entity
      return
    end
    
    # Find or create the topic (case-insensitive)
    topic = Topic.find_or_create_by_name(topic_name)
    
    if topic.persisted?
      @verse_topic = VerseTopic.new(
        bible_verse: @bible_verse,
        topic: topic,
        user: current_user
      )
      
      # Set explanation if provided
      if params[:verse_topic][:explanation].present?
        @verse_topic.explanation = params[:verse_topic][:explanation]
      end
      
      if @verse_topic.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace("topics-list", partial: "verse_topics/topics_list", locals: { bible_verse: @bible_verse })
            ]
          end
          format.html { redirect_to bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), notice: "Verse added to topic '#{topic.name}' successfully." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    else
      @verse_topic = VerseTopic.new(bible_verse: @bible_verse)
      @verse_topic.errors.add(:topic_name, topic.errors.full_messages.join(", "))
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    @verse_topic = VerseTopic.find(params[:id])
    @bible_verse = @verse_topic.bible_verse
    @book = @bible_verse.book
    @chapter = @bible_verse.chapter
    @verse = @bible_verse.verse
    
    if @verse_topic.user == current_user || current_user.admin?
      @verse_topic.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("topics-list", partial: "verse_topics/topics_list", locals: { bible_verse: @bible_verse })
          ]
        end
        format.html { redirect_back(fallback_location: bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), notice: "Topic removed from verse.") }
      end
    else
      redirect_back(fallback_location: bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), alert: "You don't have permission to remove this topic.")
    end
  end
  
  private
  
  def set_bible_verse
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verse = params[:verse].to_i
    @bible_verse = BibleVerse.find_by(book: @book, chapter: @chapter, verse: @verse)
    
    unless @bible_verse
      redirect_to bible_verse_chapters_path(book: @book), alert: "Verse not found"
    end
  end
end

