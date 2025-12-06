class VerseTopicsController < ApplicationController
  include Authorizable
  before_action :authenticate_user!
  before_action :set_bible_verse, except: [:edit, :update, :destroy]
  before_action :set_verse_topic, only: [:edit, :update, :destroy]
  
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
  
  def edit
    authorize_edit!(@verse_topic)
  end
  
  def update
    authorize_edit!(@verse_topic)
    
    if @verse_topic.update(verse_topic_params)
      respond_to do |format|
        format.turbo_stream do
          # Determine context: topic page or verse page
          if params[:topic_id].present?
            @topic = Topic.find(params[:topic_id])
            verse_topics = @topic.verse_topics
                                 .includes(:bible_verse, :user)
                                 .order('bible_verses.book ASC, bible_verses.chapter ASC, bible_verses.verse ASC')
            @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
            verse_count = @grouped_verse_topics.sum { |g| g.map { |vt| vt.bible_verse }.uniq.length }
            
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace("topic-verses-list", partial: "topics/verses_list", locals: { grouped_verse_topics: @grouped_verse_topics, topic: @topic }),
              turbo_stream.replace("verse-count", partial: "topics/verse_count", locals: { count: verse_count })
            ]
          else
            @bible_verse = @verse_topic.bible_verse
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace("topics-list", partial: "verse_topics/topics_list", locals: { bible_verse: @bible_verse })
            ]
          end
        end
        format.html { 
          if params[:topic_id].present?
            redirect_to topic_path(params[:topic_id]), notice: "Explanation updated successfully."
          else
            redirect_to bible_verse_show_path(
              book: @verse_topic.bible_verse.book,
              chapter: @verse_topic.bible_verse.chapter,
              verse: @verse_topic.bible_verse.verse
            ), notice: "Explanation updated successfully."
          end
        }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("modal", partial: "verse_topics/edit", locals: { verse_topic: @verse_topic, topic_id: params[:topic_id] })
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    authorize_delete!(@verse_topic)
    
    @bible_verse = @verse_topic.bible_verse
    @topic = @verse_topic.topic
    @book = @bible_verse.book
    @chapter = @bible_verse.chapter
    @verse = @bible_verse.verse
    
    @verse_topic.destroy
    
    respond_to do |format|
      format.turbo_stream do
        # Determine context: topic page or verse page
        if params[:topic_id].present?
          verse_topics = @topic.verse_topics
                               .includes(:bible_verse, :user)
                               .order('bible_verses.book ASC, bible_verses.chapter ASC, bible_verses.verse ASC')
          @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
          verse_count = @grouped_verse_topics.sum { |g| g.map { |vt| vt.bible_verse }.uniq.length }
          
          render turbo_stream: [
            turbo_stream.replace("topic-verses-list", partial: "topics/verses_list", locals: { grouped_verse_topics: @grouped_verse_topics, topic: @topic }),
            turbo_stream.replace("verse-count", partial: "topics/verse_count", locals: { count: verse_count })
          ]
        else
          render turbo_stream: [
            turbo_stream.replace("topics-list", partial: "verse_topics/topics_list", locals: { bible_verse: @bible_verse })
          ]
        end
      end
      format.html { 
        if params[:topic_id].present?
          redirect_to topic_path(@topic), notice: "Explanation removed successfully."
        else
          redirect_back(fallback_location: bible_verse_show_path(book: @book, chapter: @chapter, verse: @verse), notice: "Topic removed from verse.")
        end
      }
    end
  end
  
  private
  
  def set_verse_topic
    @verse_topic = VerseTopic.find(params[:id])
  end
  
  def set_bible_verse
    @book = params[:book]
    @chapter = params[:chapter].to_i
    @verse = params[:verse].to_i
    @bible_verse = BibleVerse.find_by(book: @book, chapter: @chapter, verse: @verse)
    
    unless @bible_verse
      redirect_to bible_verse_chapters_path(book: @book), alert: "Verse not found"
    end
  end
  
  def verse_topic_params
    params.require(:verse_topic).permit(:explanation)
  end
  
  def group_consecutive_verses(verse_topics)
    return [] if verse_topics.empty?
    
    # First, group verse_topics by their verse (to collect all explanations for the same verse)
    verses_hash = {}
    verse_topics.each do |vt|
      verse_key = "#{vt.bible_verse.book}|#{vt.bible_verse.chapter}|#{vt.bible_verse.verse}"
      verses_hash[verse_key] ||= []
      verses_hash[verse_key] << vt
    end
    
    # Convert to array of arrays, each inner array contains all VerseTopics for one verse
    verse_groups = verses_hash.values.sort_by do |vts|
      first_vt = vts.first
      [first_vt.bible_verse.book, first_vt.bible_verse.chapter, first_vt.bible_verse.verse]
    end
    
    # Now group consecutive verses together
    groups = []
    current_group = verse_groups.first
    
    verse_groups.each_cons(2) do |prev_group, curr_group|
      prev_verse = prev_group.first.bible_verse
      curr_verse = curr_group.first.bible_verse
      
      # Check if verses are consecutive (same book, same chapter, verse number is +1)
      if prev_verse.book == curr_verse.book && 
         prev_verse.chapter == curr_verse.chapter && 
         curr_verse.verse == prev_verse.verse + 1
        # Merge the groups (flatten to combine all VerseTopics)
        current_group = current_group + curr_group
      else
        groups << current_group
        current_group = curr_group
      end
    end
    
    groups << current_group
    groups
  end
end

