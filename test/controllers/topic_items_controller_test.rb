require "test_helper"

class TopicItemsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "topic-item-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Topic Pinner",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "topic-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other Pinner",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @topic = Topic.create!(name: "Hope-#{SecureRandom.hex(3)}")
    @note = Note.create!(
      title: "Pinned note",
      user: @user,
      status: "published",
      content: "Body"
    )
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "new renders pin modal" do
    get new_topic_item_path(itemable_type: "Note", itemable_id: @note.id)
    assert_response :success
    assert_match "Add to Topic", response.body
  end

  test "create pins note to topic" do
    assert_difference -> { TopicItem.count }, 1 do
      post topic_items_path, params: {
        topic_item: {
          topic_name: @topic.name,
          itemable_type: "Note",
          itemable_id: @note.id,
          note: "Related to hope"
        }
      }
    end

    item = TopicItem.last
    assert_equal @topic, item.topic
    assert_equal @note, item.itemable
    assert_equal @user, item.user
    assert_redirected_to note_path(@note)
  end

  test "create rejects draft note" do
    draft = Note.create!(
      title: "Draft",
      user: @user,
      status: "draft",
      content: "Draft body"
    )

    assert_no_difference -> { TopicItem.count } do
      post topic_items_path, params: {
        topic_item: {
          topic_name: @topic.name,
          itemable_type: "Note",
          itemable_id: draft.id
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "destroy removes own pin" do
    item = TopicItem.create!(topic: @topic, user: @user, itemable: @note)

    assert_difference -> { TopicItem.count }, -1 do
      delete topic_item_path(item)
    end
    assert_redirected_to note_path(@note)
  end

  test "destroy forbids other users pin" do
    item = TopicItem.create!(topic: @topic, user: @other, itemable: @note)

    assert_no_difference -> { TopicItem.count } do
      delete topic_item_path(item)
    end
  end

  test "topic show includes pinned notes" do
    TopicItem.create!(topic: @topic, user: @user, itemable: @note)

    get topic_path(@topic)
    assert_response :success
    assert_match "Pinned content", response.body
    assert_match @note.title, response.body
  end
end
