class AddTrigramIndexToBibleVersesText < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    add_index :bible_verses, :text,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_bible_verses_on_text_trgm",
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :bible_verses,
                 name: "index_bible_verses_on_text_trgm",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
