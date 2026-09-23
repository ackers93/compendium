class ContentImportMapping < ApplicationRecord
  validates :source, :record_type, presence: true
  validates :source_id, :local_id, presence: true
  validates :source_id, uniqueness: { scope: [:source, :record_type] }
end
