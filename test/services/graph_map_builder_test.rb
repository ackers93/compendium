require "test_helper"

class GraphMapBuilderTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "map-builder-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Map Builder",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "map-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other User",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @verse = BibleVerse.create!(
      book: "John",
      chapter: 3,
      verse: 16,
      text: "For God so loved the world",
      testament: "NT"
    )
    @other_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 8,
      text: "But God commendeth his love toward us",
      testament: "NT"
    )
    @lonely_verse = BibleVerse.create!(
      book: "Jude",
      chapter: 1,
      verse: 1,
      text: "Jude, the servant of Jesus Christ",
      testament: "NT"
    )
  end

  test "omits isolated verses with no connections" do
    topic = Topic.create!(name: "Love-#{SecureRandom.hex(3)}")
    VerseTopic.create!(user: @user, bible_verse: @verse, topic: topic)

    graph = GraphMapBuilder.call(viewer: @user)
    node_ids = graph[:nodes].map { |n| n[:id] }

    assert_includes node_ids, "BibleVerse:#{@verse.id}"
    assert_includes node_ids, "Topic:#{topic.id}"
    assert_not_includes node_ids, "BibleVerse:#{@lonely_verse.id}"
  end

  test "hides draft notes from other users" do
    draft = Note.create!(title: "Secret draft", user: @user, status: "draft", content: "Private")
    VerseMention.create!(bible_verse: @verse, mentionable: draft)

    as_owner = GraphMapBuilder.call(viewer: @user)
    assert_includes as_owner[:nodes].map { |n| n[:id] }, "Note:#{draft.id}"

    as_other = GraphMapBuilder.call(viewer: @other)
    assert_not_includes as_other[:nodes].map { |n| n[:id] }, "Note:#{draft.id}"
    assert_not_includes as_other[:nodes].map { |n| n[:id] }, "BibleVerse:#{@verse.id}"
  end

  test "include_node_types can omit comments" do
    Comment.create!(user: @user, commentable: @verse, content: "A comment on John 3:16")

    with_comments = GraphMapBuilder.call(viewer: @user)
    assert_includes with_comments[:nodes].map { |n| n[:type] }, "Comment"

    without_comments = GraphMapBuilder.call(
      viewer: @user,
      include_node_types: GraphMapBuilder::NODE_TYPES - ["Comment"]
    )
    assert_not_includes without_comments[:nodes].map { |n| n[:type] }, "Comment"
    assert_includes without_comments[:types].map { |t| t[:id] }, "BibleVerse"
    assert_not_includes without_comments[:types].map { |t| t[:id] }, "Comment"
  end

  test "sets node size from degree and includes urls" do
    topic = Topic.create!(name: "Grace-#{SecureRandom.hex(3)}")
    VerseTopic.create!(user: @user, bible_verse: @verse, topic: topic)
    CrossReference.create!(user: @user, source_verse: @verse, target_verse: @other_verse)

    graph = GraphMapBuilder.call(viewer: @user)
    verse_node = graph[:nodes].find { |n| n[:id] == "BibleVerse:#{@verse.id}" }

    assert verse_node
    assert verse_node[:degree] >= 2
    assert verse_node[:size] >= GraphMapBuilder::MIN_NODE_SIZE
    assert_match %r{/bible_verses/John/3/16}, verse_node[:url]
  end

  test "cross references link verses directly without a hub node" do
    xref = CrossReference.create!(user: @user, source_verse: @verse, target_verse: @other_verse)

    graph = GraphMapBuilder.call(viewer: @user)
    node_ids = graph[:nodes].map { |n| n[:id] }
    edge = graph[:edges].find { |e|
      e[:type] == "cross_reference" &&
        [e[:source], e[:target]].to_set == ["BibleVerse:#{@verse.id}", "BibleVerse:#{@other_verse.id}"].to_set
    }

    assert edge, "expected verse-to-verse cross reference edge"
    assert_includes node_ids, "BibleVerse:#{@verse.id}"
    assert_includes node_ids, "BibleVerse:#{@other_verse.id}"
    assert_not_includes node_ids, "CrossReference:#{xref.id}"
    assert_not_includes graph[:types].map { |t| t[:id] }, "CrossReference"
  end

  test "cross reference ranges expand to every target verse" do
    mid = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 9,
      text: "Much more then, being now justified by his blood",
      testament: "NT"
    )
    end_verse = BibleVerse.create!(
      book: "Romans",
      chapter: 5,
      verse: 10,
      text: "For if, when we were enemies, we were reconciled",
      testament: "NT"
    )
    CrossReference.create!(
      user: @user,
      source_verse: @verse,
      target_verse: @other_verse,
      target_end_verse: end_verse
    )

    graph = GraphMapBuilder.call(viewer: @user)
    node_ids = graph[:nodes].map { |n| n[:id] }
    targets = [@other_verse, mid, end_verse].map { |v| "BibleVerse:#{v.id}" }

    assert_includes node_ids, "BibleVerse:#{@verse.id}"
    targets.each { |id| assert_includes node_ids, id }

    targets.each do |target_id|
      edge = graph[:edges].find { |e|
        e[:type] == "cross_reference" &&
          [e[:source], e[:target]].to_set == ["BibleVerse:#{@verse.id}", target_id].to_set
      }
      assert edge, "expected edge from source to #{target_id}"
    end
  end

  test "includes comment nodes linked to their commentable" do
    comment = Comment.create!(user: @user, commentable: @verse, content: "Insightful note")

    graph = GraphMapBuilder.call(viewer: @user)
    edge = graph[:edges].find { |e|
      e[:type] == "comment" &&
        [e[:source], e[:target]].include?("Comment:#{comment.id}") &&
        [e[:source], e[:target]].include?("BibleVerse:#{@verse.id}")
    }

    assert edge, "expected comment edge to verse"
  end

  test "comments on cross references link to the involved verses" do
    xref = CrossReference.create!(user: @user, source_verse: @verse, target_verse: @other_verse)
    comment = Comment.create!(user: @user, commentable: xref, content: "Great connection")

    graph = GraphMapBuilder.call(viewer: @user)
    node_ids = graph[:nodes].map { |n| n[:id] }

    assert_includes node_ids, "Comment:#{comment.id}"
    assert_not_includes node_ids, "CrossReference:#{xref.id}"

    [@verse, @other_verse].each do |verse|
      edge = graph[:edges].find { |e|
        e[:type] == "comment" &&
          [e[:source], e[:target]].to_set == ["Comment:#{comment.id}", "BibleVerse:#{verse.id}"].to_set
      }
      assert edge, "expected comment edge to BibleVerse:#{verse.id}"
    end
  end
end
