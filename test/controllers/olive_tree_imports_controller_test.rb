require "test_helper"

class OliveTreeImportsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "olive-ctrl-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Olive Controller",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    BibleVerse.create!(book: "Acts", chapter: 8, verse: 24, text: "Then answered Simon", testament: "NT")
    BibleVerse.create!(book: "Acts", chapter: 8, verse: 26, text: "And the angel of the Lord", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    BibleVerse.create!(book: "1 John", chapter: 5, verse: 7, text: "For there are three", testament: "NT")
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "imports olive tree notes from uploaded csv" do
    assert_difference -> { Comment.count }, 4 do
      post olive_tree_import_path, params: {
        file: fixture_file_upload("olive_tree/notes_export.csv", "text/csv")
      }
    end

    assert_redirected_to bulk_upload_hub_path(tab: "olive_tree")
    follow_redirect!
    assert_match(/Imported 4 notes/, flash[:notice])
  end

  test "requires a csv file" do
    post olive_tree_import_path, params: {}

    assert_response :unprocessable_entity
    assert_match(/Choose an Olive Tree CSV/, flash[:alert])
  end
end
