class TopicItemsController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :authorize_create!, only: %i[new create]
  before_action :set_itemable, only: %i[new create]
  before_action :set_topic_item, only: %i[edit update destroy]

  def new
    @topic_item = TopicItem.new(itemable: @itemable)
  end

  def create
    topic_name = params[:topic_item][:topic_name].to_s.strip

    if topic_name.blank?
      @topic_item = TopicItem.new(itemable: @itemable)
      @topic_item.errors.add(:topic_name, "can't be blank")
      render :new, status: :unprocessable_entity
      return
    end

    topic = Topic.find_or_create_by_name(topic_name)

    if topic.persisted?
      @topic_item = TopicItem.new(
        itemable: @itemable,
        topic: topic,
        user: current_user
      )

      if params[:topic_item][:note].present?
        @topic_item.note = params[:topic_item][:note]
      end

      if @topic_item.save
        respond_to do |format|
          format.turbo_stream do
            streams = [turbo_stream.replace("modal", "")]
            if [Note, BibleThread, Chiasm].include?(@itemable.class)
              streams << turbo_stream.replace(
                topic_items_list_dom_id(@itemable),
                partial: "topic_items/topics_list",
                locals: { itemable: @itemable }
              )
            end
            render turbo_stream: streams
          end
          format.html { redirect_to itemable_redirect_path(@itemable), notice: "Pinned to topic '#{topic.name}'." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    else
      @topic_item = TopicItem.new(itemable: @itemable)
      @topic_item.errors.add(:topic_name, topic.errors.full_messages.join(", "))
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_edit!(@topic_item)
  end

  def update
    authorize_edit!(@topic_item)

    if @topic_item.update(topic_item_params)
      respond_to do |format|
        format.turbo_stream do
          if params[:topic_id].present?
            @topic = Topic.find(params[:topic_id])
            load_topic_show_data(@topic)
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace(
                "topic-pinned-content",
                partial: "topics/pinned_content",
                locals: { topic_items_by_type: @topic_items_by_type, topic: @topic }
              )
            ]
          else
            itemable = @topic_item.itemable
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace(
                topic_items_list_dom_id(itemable),
                partial: "topic_items/topics_list",
                locals: { itemable: itemable }
              )
            ]
          end
        end
        format.html do
          if params[:topic_id].present?
            redirect_to topic_path(params[:topic_id]), notice: "Pin updated."
          else
            redirect_to itemable_redirect_path(@topic_item.itemable), notice: "Pin updated."
          end
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_delete!(@topic_item)

    itemable = @topic_item.itemable
    topic = @topic_item.topic
    @topic_item.destroy

    respond_to do |format|
      format.turbo_stream do
        if params[:topic_id].present?
          load_topic_show_data(topic)
          render turbo_stream: [
            turbo_stream.replace(
              "topic-pinned-content",
              partial: "topics/pinned_content",
              locals: { topic_items_by_type: @topic_items_by_type, topic: topic }
            )
          ]
        else
          render turbo_stream: [
            turbo_stream.replace(
              topic_items_list_dom_id(itemable),
              partial: "topic_items/topics_list",
              locals: { itemable: itemable }
            )
          ]
        end
      end
      format.html do
        if params[:topic_id].present?
          redirect_to topic_path(topic), notice: "Removed from topic."
        else
          redirect_to itemable_redirect_path(itemable), notice: "Removed from topic."
        end
      end
    end
  end

  private

  def set_itemable
    type = params[:itemable_type].presence || params.dig(:topic_item, :itemable_type)
    id = params[:itemable_id].presence || params.dig(:topic_item, :itemable_id)

    unless TopicItem::ITEMABLE_TYPES.include?(type)
      redirect_to root_path, alert: "Invalid content type."
      return
    end

    @itemable = type.constantize.find(id)
  end

  def set_topic_item
    @topic_item = TopicItem.find(params[:id])
  end

  def topic_item_params
    params.require(:topic_item).permit(:note)
  end

  def topic_items_list_dom_id(itemable)
    "topic-items-list-#{itemable.class.name.underscore}-#{itemable.id}"
  end

  def itemable_redirect_path(itemable)
    case itemable
    when Note
      note_path(itemable)
    when BibleThread
      bible_thread_path(itemable)
    when Chiasm
      chiasm_path(itemable)
    when Comment
      path_for_comment_redirect(itemable)
    when CrossReference
      source = itemable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    else
      root_path
    end
  end

  def path_for_comment_redirect(comment)
    commentable = comment.commentable
    case commentable
    when Note
      note_path(commentable)
    when CrossReference
      source = commentable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    when BibleVerse
      bible_verse_show_path(book: commentable.book, chapter: commentable.chapter, verse: commentable.verse)
    else
      root_path
    end
  end

  def load_topic_show_data(topic)
    items = topic.topic_items
                 .includes(:user, :itemable, :rich_text_note)
                 .order(created_at: :desc)
                 .select { |ti| ti.visible_to?(current_user) }
    @topic_items_by_type = TopicItem::ITEMABLE_TYPES.index_with { |type|
      items.select { |ti| ti.itemable_type == type }
    }.reject { |_type, list| list.empty? }
  end
end
