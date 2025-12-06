class Topic < ApplicationRecord
  has_many :verse_topics, dependent: :destroy
  has_many :bible_verses, through: :verse_topics
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  # Normalize name before saving
  before_save :normalize_name
  
  # Case-insensitive search for autocomplete
  scope :search_by_name, ->(query) { where("LOWER(name) LIKE ?", "%#{query.downcase}%") }
  
  # Find or create by name (case-insensitive)
  def self.find_or_create_by_name(name)
    normalized_name = name.to_s.strip
    find_by("LOWER(name) = ?", normalized_name.downcase) || create(name: normalized_name)
  end
  
  private
  
  def normalize_name
    self.name = name.to_s.strip if name.present?
  end
end
