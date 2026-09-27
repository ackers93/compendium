class CreateDiscussionQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :discussion_questions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :questionable, polymorphic: true, null: false, index: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
