class ChangeVerseTopicsUniqueConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the old unique constraint on verse_id + topic_id
    remove_index :verse_topics, [:bible_verse_id, :topic_id]
    
    # Add new unique constraint on verse_id + topic_id + user_id
    # This allows multiple users to add the same verse to the same topic,
    # but prevents the same user from adding it twice
    add_index :verse_topics, [:bible_verse_id, :topic_id, :user_id], unique: true, name: 'index_verse_topics_on_verse_topic_user'
  end
end
