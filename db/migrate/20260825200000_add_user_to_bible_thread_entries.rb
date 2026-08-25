class AddUserToBibleThreadEntries < ActiveRecord::Migration[8.0]
  def up
    add_reference :bible_thread_entries, :user, foreign_key: true, null: true

    execute <<~SQL.squish
      UPDATE bible_thread_entries
      SET user_id = bible_threads.user_id
      FROM bible_threads
      WHERE bible_thread_entries.bible_thread_id = bible_threads.id
        AND bible_thread_entries.user_id IS NULL
    SQL
  end

  def down
    remove_reference :bible_thread_entries, :user, foreign_key: true
  end
end
