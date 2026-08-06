module ApplicationHelper
  def bible_verse_path_for(commentable)
    if commentable.is_a?(BibleVerse)
      bible_verse_show_path(book: commentable.book, chapter: commentable.chapter, verse: commentable.verse)
    else
      polymorphic_path(commentable)
    end
  end
  
  def bible_verse_comment_path_for(commentable, comment)
    if commentable.is_a?(BibleVerse)
      bible_verse_comment_path(book: commentable.book, chapter: commentable.chapter, verse: commentable.verse, id: comment.id)
    else
      polymorphic_path([commentable, comment])
    end
  end
  
  def edit_bible_verse_comment_path_for(commentable, comment)
    if commentable.is_a?(BibleVerse)
      edit_bible_verse_comment_path(book: commentable.book, chapter: commentable.chapter, verse: commentable.verse, id: comment.id)
    else
      edit_polymorphic_path([commentable, comment])
    end
  end
  
  def bible_verse_form_url_for(comment)
    if comment.new_record?
      if comment.commentable.is_a?(BibleVerse)
        bible_verse_comments_path(book: comment.commentable.book, chapter: comment.commentable.chapter, verse: comment.commentable.verse)
      else
        polymorphic_path([comment.commentable, comment])
      end
    else
      if comment.commentable.is_a?(BibleVerse)
        bible_verse_comment_path(book: comment.commentable.book, chapter: comment.commentable.chapter, verse: comment.commentable.verse, id: comment.id)
      else
        # For cross-reference comments, use the individual comment routes
        comment_path(comment)
      end
    end
  end
  
  def plain_text_from_rich_text(rich_text, length = nil)
    return "" unless rich_text.present?
    text = rich_text.to_plain_text
    if length && text.length > length
      truncate(text, length: length, omission: '...')
    else
      text
    end
  end

  def verse_mention_title(mentionable)
    case mentionable
    when Note
      mentionable.title
    when Comment
      commentable = mentionable.commentable
      case commentable
      when Note
        commentable.title
      when BibleVerse
        commentable.reference
      when CrossReference
        commentable.connection_label
      else
        "Comment"
      end
    else
      "Mention"
    end
  end

  def verse_mention_kind_label(mentionable)
    case mentionable
    when Note
      "Note"
    when Comment
      commentable = mentionable.commentable
      case commentable
      when Note
        "Comment on note"
      when BibleVerse
        "Comment on #{commentable.reference}"
      when CrossReference
        "Comment on cross-reference"
      else
        "Comment"
      end
    else
      "Mention"
    end
  end

  def verse_mention_path(mentionable)
    case mentionable
    when Note
      note_path(mentionable)
    when Comment
      commentable = mentionable.commentable
      case commentable
      when Note
        note_path(commentable)
      when BibleVerse
        bible_verse_show_path(book: commentable.book, chapter: commentable.chapter, verse: commentable.verse)
      when CrossReference
        source = commentable.source_verse
        bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
      else
        root_path
      end
    else
      root_path
    end
  end

  def theme_style_tag
    return unless user_signed_in?

    declarations = current_user.theme_css_variables.map { |key, value| "#{key}: #{value};" }.join("\n      ")
    tag.style(":root {\n      #{declarations}\n    }".html_safe)
  end
end
