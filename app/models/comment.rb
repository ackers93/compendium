class Comment < ApplicationRecord
  include Flaggable
  
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_rich_text :content
  
  validates :content, presence: true
end