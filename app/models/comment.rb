class Comment < ApplicationRecord
    belongs_to :user
    belongs_to :note 
    has_rich_text :content
  end