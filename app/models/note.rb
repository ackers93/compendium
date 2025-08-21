class Note < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy
  has_rich_text :content
  acts_as_taggable_on :tags
  
  validates :title, presence: true
  validates :user_id, presence: true
end