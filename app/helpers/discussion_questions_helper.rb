module DiscussionQuestionsHelper
  include ActionView::RecordIdentifier

  def discussion_question_parent_path(discussion_question)
    questionable_path(discussion_question.questionable, anchor: dom_id(discussion_question))
  end

  def discussion_question_create_path(questionable)
    case questionable
    when BibleVerse
      bible_verse_discussion_questions_path(
        book: questionable.book,
        chapter: questionable.chapter,
        verse: questionable.verse
      )
    when Topic
      topic_discussion_questions_path(questionable)
    end
  end

  def questionable_path(questionable, anchor: nil)
    case questionable
    when BibleVerse
      bible_verse_show_path(
        book: questionable.book,
        chapter: questionable.chapter,
        verse: questionable.verse,
        anchor: anchor
      )
    when Topic
      topic_path(questionable, anchor: anchor)
    else
      discussion_questions_path
    end
  end
end
