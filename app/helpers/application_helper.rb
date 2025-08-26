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
end
