class VerseTopic < ApplicationRecord
  include Flaggable
  
  belongs_to :bible_verse
  belongs_to :topic
  belongs_to :user
  
  has_rich_text :explanation
  
  validates :bible_verse_id, uniqueness: { scope: :topic_id, message: "This verse is already associated with this topic" }
end
