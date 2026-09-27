class CreateCommunityQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :community_questions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end

    create_table :community_answers do |t|
      t.references :community_question, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :community_answers }

      t.timestamps
    end
  end
end
