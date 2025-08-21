class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments, id: { type: :integer, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :user_id, null: false
      t.integer :upvotes
      t.datetime :created_at, precision: nil
      t.integer :note_id
      t.integer :bible_verse_id
      t.string :commentable_type, null: false
      t.bigint :commentable_id, null: false

      t.index [:commentable_type, :commentable_id], name: "index_comments_on_commentable"
    end
  end
end