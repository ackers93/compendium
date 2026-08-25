module NotificationsHelper
  include ActionView::RecordIdentifier

  def notification_message(notification)
    actor_name = notification.actor.display_name

    case notification.action
    when "comment"
      "#{actor_name} commented on your #{comment_target_label(notification.notifiable)}"
    when "reply"
      "#{actor_name} replied to your comment"
    when "topic_contribution"
      topic_name = notification.notifiable&.topic&.name || "a topic"
      "#{actor_name} added a verse to #{topic_name}"
    when "thread_contribution"
      thread_title = notification.notifiable&.bible_thread&.title || "a thread"
      "#{actor_name} added a verse to \"#{thread_title}\""
    when "review_requested"
      "An admin requested a review of your #{flaggable_label(notification.notifiable)}"
    else
      "#{actor_name} sent you a notification"
    end
  end

  def notification_path_for(notification)
    notifiable = notification.notifiable
    return notifications_path if notifiable.nil?

    case notification.action
    when "review_requested"
      my_flagged_content_path(status: "review_requested")
    when "topic_contribution"
      topic_path(notifiable.topic)
    when "thread_contribution"
      bible_thread_path(notifiable.bible_thread)
    when "comment", "reply"
      path_for_comment(notifiable)
    else
      notifications_path
    end
  rescue StandardError
    notifications_path
  end

  def notification_icon(notification)
    case notification.action
    when "comment" then "fa-solid fa-comment"
    when "reply" then "fa-solid fa-reply"
    when "topic_contribution" then "fa-solid fa-bookmark"
    when "thread_contribution" then "fa-solid fa-link"
    when "review_requested" then "fa-solid fa-flag"
    else "fa-solid fa-bell"
    end
  end

  private

  def comment_target_label(comment)
    return "content" unless comment

    case comment.commentable
    when Note
      "note \"#{comment.commentable.title}\""
    when CrossReference
      "cross-reference (#{comment.commentable.connection_label})"
    when BibleVerse
      "verse #{comment.commentable.reference}"
    else
      "content"
    end
  end

  def flaggable_label(flag)
    return "content" unless flag&.flaggable

    case flag.flaggable_type
    when "Note" then "note \"#{flag.flaggable.title}\""
    when "Comment" then "comment"
    when "CrossReference" then "cross-reference"
    when "BibleThread" then "thread \"#{flag.flaggable.title}\""
    when "Chiasm" then "chiasm \"#{flag.flaggable.title}\""
    else flag.flaggable_type.underscore.humanize.downcase
    end
  end

  def path_for_comment(comment)
    commentable = comment.commentable

    case commentable
    when Note
      note_path(commentable, anchor: dom_id(comment))
    when CrossReference
      source = commentable.source_verse
      bible_verse_show_path(book: source.book, chapter: source.chapter, verse: source.verse)
    when BibleVerse
      bible_verse_show_path(
        book: commentable.book,
        chapter: commentable.chapter,
        verse: commentable.verse,
        anchor: dom_id(comment)
      )
    else
      notifications_path
    end
  end
end
