class Note < ApplicationRecord
  belongs_to :user
  has_many :comment
  has_rich_text :content
  acts_as_taggable_on :tags
end