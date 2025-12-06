# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_06_053250) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bible_thread_entries", force: :cascade do |t|
    t.bigint "bible_thread_id", null: false
    t.bigint "bible_verse_id", null: false
    t.integer "position"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bible_thread_id", "position"], name: "index_bible_thread_entries_on_bible_thread_id_and_position"
    t.index ["bible_thread_id"], name: "index_bible_thread_entries_on_bible_thread_id"
    t.index ["bible_verse_id"], name: "index_bible_thread_entries_on_bible_verse_id"
  end

  create_table "bible_threads", force: :cascade do |t|
    t.string "title"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bible_threads_on_user_id"
  end

  create_table "bible_verses", force: :cascade do |t|
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "verse", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "testament"
    t.index ["book", "chapter", "verse"], name: "index_bible_verses_on_book_and_chapter_and_verse", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "upvotes"
    t.datetime "created_at", precision: nil
    t.integer "note_id"
    t.integer "bible_verse_id"
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
  end

  create_table "content_flags", force: :cascade do |t|
    t.string "flaggable_type", null: false
    t.bigint "flaggable_id", null: false
    t.bigint "user_id", null: false
    t.text "reason"
    t.string "status", default: "pending", null: false
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flaggable_type", "flaggable_id"], name: "index_content_flags_on_flaggable"
    t.index ["flaggable_type", "flaggable_id"], name: "index_content_flags_on_flaggable_type_and_flaggable_id"
    t.index ["resolved_by_id"], name: "index_content_flags_on_resolved_by_id"
    t.index ["status"], name: "index_content_flags_on_status"
    t.index ["user_id"], name: "index_content_flags_on_user_id"
  end

  create_table "cross_references", force: :cascade do |t|
    t.bigint "source_verse_id", null: false
    t.bigint "target_verse_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["source_verse_id", "target_verse_id"], name: "index_cross_references_on_source_and_target", unique: true
    t.index ["source_verse_id"], name: "index_cross_references_on_source_verse_id"
    t.index ["target_verse_id"], name: "index_cross_references_on_target_verse_id"
    t.index ["user_id"], name: "index_cross_references_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.integer "user_id", null: false
    t.string "tag_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "published", null: false
    t.index ["status"], name: "index_notes_on_status"
    t.index ["title"], name: "index_notes_on_title"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
  end

  create_table "topics", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_topics_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "ecclesia"
    t.string "role"
    t.string "otp_secret"
    t.datetime "otp_sent_at"
    t.boolean "otp_required_for_login", default: true, null: false
    t.datetime "onboarding_completed_at"
    t.datetime "admin_onboarding_completed_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "verse_topics", force: :cascade do |t|
    t.bigint "bible_verse_id", null: false
    t.bigint "topic_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bible_verse_id", "topic_id", "user_id"], name: "index_verse_topics_on_verse_topic_user", unique: true
    t.index ["bible_verse_id"], name: "index_verse_topics_on_bible_verse_id"
    t.index ["topic_id"], name: "index_verse_topics_on_topic_id"
    t.index ["user_id"], name: "index_verse_topics_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bible_thread_entries", "bible_threads"
  add_foreign_key "bible_thread_entries", "bible_verses"
  add_foreign_key "bible_threads", "users"
  add_foreign_key "content_flags", "users"
  add_foreign_key "content_flags", "users", column: "resolved_by_id"
  add_foreign_key "cross_references", "bible_verses", column: "source_verse_id"
  add_foreign_key "cross_references", "bible_verses", column: "target_verse_id"
  add_foreign_key "cross_references", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "verse_topics", "bible_verses"
  add_foreign_key "verse_topics", "topics"
  add_foreign_key "verse_topics", "users"
end
