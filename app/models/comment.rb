class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_many :content_flags, as: :flaggable, dependent: :destroy
  has_rich_text :content
  
  validates :content, presence: true
end