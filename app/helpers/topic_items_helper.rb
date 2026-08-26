module TopicItemsHelper
  def topic_items_list_dom_id(itemable)
    "topic-items-list-#{itemable.class.name.underscore}-#{itemable.id}"
  end

  def topic_item_itemable_path(topic_item)
    itemable = topic_item.itemable
    return root_path if itemable.nil?

    case itemable
    when Note
      note_path(itemable)
    when BibleThread
      bible_thread_path(itemable)
    when Chiasm
      chiasm_path(itemable)
    when Comment
      path_for_commentable_comment(itemable)
    when CrossReference
      source = itemable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    else
      root_path
    end
  end

  def new_topic_item_path_for(itemable)
    new_topic_item_path(itemable_type: itemable.class.name, itemable_id: itemable.id)
  end

  private

  def path_for_commentable_comment(comment)
    commentable = comment.commentable
    case commentable
    when Note
      note_path(commentable, anchor: ActionView::RecordIdentifier.dom_id(comment))
    when CrossReference
      source = commentable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    when BibleVerse
      bible_verse_show_path(
        book: commentable.book,
        chapter: commentable.chapter,
        verse: commentable.verse,
        anchor: ActionView::RecordIdentifier.dom_id(comment)
      )
    else
      root_path
    end
  end
end
