class AddContentAuthorToContentFlags < ActiveRecord::Migration[8.0]
  FLAGABLE_TABLES = {
    "Note" => "notes",
    "Comment" => "comments",
    "CrossReference" => "cross_references",
    "BibleThread" => "bible_threads",
    "Chiasm" => "chiasms",
    "TopicItem" => "topic_items",
    "VerseTopic" => "verse_topics"
  }.freeze

  def up
    add_reference :content_flags, :content_author,
                  foreign_key: { to_table: :users },
                  null: true,
                  index: false

    FLAGABLE_TABLES.each do |flaggable_type, table_name|
      execute <<-SQL.squish
        UPDATE content_flags
        SET content_author_id = #{table_name}.user_id
        FROM #{table_name}
        WHERE content_flags.flaggable_type = '#{flaggable_type}'
          AND content_flags.flaggable_id = #{table_name}.id
          AND content_flags.content_author_id IS NULL
      SQL
    end

    add_index :content_flags, [:content_author_id, :status],
              name: "index_content_flags_on_content_author_id_and_status"
  end

  def down
    remove_index :content_flags, name: "index_content_flags_on_content_author_id_and_status"
    remove_reference :content_flags, :content_author, foreign_key: { to_table: :users }, index: false
  end
end
