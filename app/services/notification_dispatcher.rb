class NotificationDispatcher
  class << self
    def comment_created(comment)
      actor = comment.user
      return unless actor

      notified_ids = []

      if comment.reply? && comment.parent&.user
        create_notification(
          recipient: comment.parent.user,
          actor: actor,
          action: "reply",
          notifiable: comment
        )
        notified_ids << comment.parent.user_id
      end

      owner = commentable_owner(comment.commentable)
      if owner && !notified_ids.include?(owner.id)
        create_notification(
          recipient: owner,
          actor: actor,
          action: "comment",
          notifiable: comment
        )
      end
    end

    def verse_topic_created(verse_topic)
      actor = verse_topic.user
      topic = verse_topic.topic
      return unless actor && topic

      notify_topic_contributors(topic: topic, actor: actor, notifiable: verse_topic)
    end

    def topic_item_created(topic_item)
      actor = topic_item.user
      topic = topic_item.topic
      return unless actor && topic

      notify_topic_contributors(topic: topic, actor: actor, notifiable: topic_item)
    end

    def thread_entry_created(entry)
      actor = entry.user
      thread = entry.bible_thread
      return unless actor && thread

      recipient_ids = thread.contributor_ids - [actor.id]

      User.where(id: recipient_ids).find_each do |recipient|
        create_notification(
          recipient: recipient,
          actor: actor,
          action: "thread_contribution",
          notifiable: entry
        )
      end
    end

    def review_requested(content_flag, actor:)
      author = content_flag.content_author
      return unless author && actor

      create_notification(
        recipient: author,
        actor: actor,
        action: "review_requested",
        notifiable: content_flag
      )
    end

    private

    def notify_topic_contributors(topic:, actor:, notifiable:)
      recipient_ids = (
        VerseTopic.where(topic_id: topic.id).distinct.pluck(:user_id) +
        TopicItem.where(topic_id: topic.id).distinct.pluck(:user_id)
      ).uniq - [actor.id]

      User.where(id: recipient_ids).find_each do |recipient|
        create_notification(
          recipient: recipient,
          actor: actor,
          action: "topic_contribution",
          notifiable: notifiable
        )
      end
    end

    def commentable_owner(commentable)
      return unless commentable.respond_to?(:user)

      commentable.user
    end

    def create_notification(recipient:, actor:, action:, notifiable:)
      return if recipient.nil? || actor.nil?
      return if recipient.id == actor.id

      Notification.create!(
        recipient: recipient,
        actor: actor,
        action: action,
        notifiable: notifiable
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("NotificationDispatcher failed: #{e.message}")
      nil
    end
  end
end
