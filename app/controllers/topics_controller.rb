class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic, only: [:show, :add_verse]
  
  # Bible book order constants
  OLD_TESTAMENT_BOOKS = BibleVersesController::OLD_TESTAMENT_BOOKS
  NEW_TESTAMENT_BOOKS = BibleVersesController::NEW_TESTAMENT_BOOKS
  
  def index
    @topics = Topic.includes(verse_topics: :bible_verse)
                   .left_joins(:verse_topics)
    
    # Apply search filter if query parameter is present
    if params[:search].present?
      @topics = @topics.search_by_name_or_verses(params[:search])
    end
    
    @topics = @topics.group('topics.id')
                     .order('COUNT(verse_topics.id) DESC, topics.name ASC')
                     .select('topics.*, COUNT(verse_topics.id) as verses_count')
  end
  
  def show
    verse_topics = @topic.verse_topics
                         .joins(:bible_verse)
                         .includes(:bible_verse, :user)
                         .order(bible_order_sql)
    @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
    @errors = []
  end
  
  def add_verse
    book = params[:book]
    chapter = params[:chapter].to_i
    verse = params[:verse].to_i
    
    bible_verse = BibleVerse.find_by(book: book, chapter: chapter, verse: verse)
    
    unless bible_verse
      @errors = ["Verse not found. Please select a valid book, chapter, and verse."]
      verse_topics = @topic.verse_topics
                           .joins(:bible_verse)
                           .includes(:bible_verse, :user)
                           .order(bible_order_sql)
      @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
      render :show, status: :unprocessable_entity
      return
    end
    
    @verse_topic = VerseTopic.new(
      bible_verse: bible_verse,
      topic: @topic,
      user: current_user
    )
    
    # Set explanation if provided
    if params[:explanation].present?
      @verse_topic.explanation = params[:explanation]
    end
    
    if @verse_topic.save
      respond_to do |format|
        format.turbo_stream do
          # Reload the verse topics for this topic
          verse_topics = @topic.verse_topics
                               .joins(:bible_verse)
                               .includes(:bible_verse, :user)
                               .order(bible_order_sql)
          @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
          @errors = []
          verse_count = @grouped_verse_topics.sum { |g| g.map { |vt| vt.bible_verse }.uniq.length }
          
          render turbo_stream: [
            turbo_stream.replace("add-verse-to-topic-form", partial: "topics/add_verse_form", locals: { errors: [] }),
            turbo_stream.replace("topic-verses-list", partial: "topics/verses_list", locals: { grouped_verse_topics: @grouped_verse_topics, topic: @topic }),
            turbo_stream.replace("verse-count", partial: "topics/verse_count", locals: { count: verse_count })
          ]
        end
        format.html { redirect_to topic_path(@topic), notice: "Verse added to topic successfully." }
      end
    else
      @errors = @verse_topic.errors.full_messages
      verse_topics = @topic.verse_topics
                           .joins(:bible_verse)
                           .includes(:bible_verse, :user)
                           .order(bible_order_sql)
      @grouped_verse_topics = group_consecutive_verses(verse_topics.to_a)
      render :show, status: :unprocessable_entity
    end
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
    @topic = Topic.find_or_create_by_name(topic_params[:name])
    
    if @topic.persisted?
      render json: { id: @topic.id, name: @topic.name }, status: :created
    else
      render json: { errors: @topic.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def group_consecutive_verses(verse_topics)
    return [] if verse_topics.empty?
    
    # Create book order hash for sorting
    all_books = OLD_TESTAMENT_BOOKS + NEW_TESTAMENT_BOOKS
    book_order = all_books.each_with_index.to_h
    
    # First, group verse_topics by their verse (to collect all explanations for the same verse)
    verses_hash = {}
    verse_topics.each do |vt|
      verse_key = "#{vt.bible_verse.book}|#{vt.bible_verse.chapter}|#{vt.bible_verse.verse}"
      verses_hash[verse_key] ||= []
      verses_hash[verse_key] << vt
    end
    
    # Convert to array of arrays, each inner array contains all VerseTopics for one verse
    # Sort by Bible order: book order, then chapter, then verse
    verse_groups = verses_hash.values.sort_by do |vts|
      first_vt = vts.first
      book_index = book_order[first_vt.bible_verse.book] || 999
      [book_index, first_vt.bible_verse.chapter, first_vt.bible_verse.verse]
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
  
  def set_topic
    @topic = Topic.find(params[:id])
  end
  
  def topic_params
    params.require(:topic).permit(:name)
  end
  
  def bible_order_sql
    # Build CASE statement for book order
    all_books = OLD_TESTAMENT_BOOKS + NEW_TESTAMENT_BOOKS
    book_order_cases = all_books.each_with_index.map { |book, index| "WHEN '#{book}' THEN #{index}" }.join(' ')
    
    # SQL order: book order (by CASE), then chapter, then verse
    Arel.sql("CASE bible_verses.book #{book_order_cases} ELSE 999 END, bible_verses.chapter ASC, bible_verses.verse ASC")
  end
end

