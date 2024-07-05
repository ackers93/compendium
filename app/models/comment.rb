class Comment < ApplicationRecord
    belongs_to :user
    belongs_to :note 
    belongs_to :bible_verse
    has_rich_text :content
  end