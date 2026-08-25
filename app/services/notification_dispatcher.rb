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

      recipient_ids = VerseTopic
        .where(topic_id: topic.id)
        .where.not(id: verse_topic.id)
        .where.not(user_id: actor.id)
        .distinct
        .pluck(:user_id)

      User.where(id: recipient_ids).find_each do |recipient|
        create_notification(
          recipient: recipient,
          actor: actor,
          action: "topic_contribution",
          notifiable: verse_topic
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
