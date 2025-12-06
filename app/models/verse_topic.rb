class VerseTopic < ApplicationRecord
  include Flaggable
  
  belongs_to :bible_verse
  belongs_to :topic
  belongs_to :user
  
  has_rich_text :explanation
  
  # Allow multiple users to add the same verse to the same topic,
  # but prevent the same user from adding it twice
  validates :bible_verse_id, uniqueness: { scope: [:topic_id, :user_id], message: "You have already added this verse to this topic" }
end
