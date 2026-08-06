class VerseMention < ApplicationRecord
  belongs_to :bible_verse
  belongs_to :mentionable, polymorphic: true

  validates :bible_verse_id, uniqueness: { scope: [:mentionable_type, :mentionable_id] }
end
