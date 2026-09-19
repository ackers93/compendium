require "test_helper"

class CsvImportsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "csv-ctrl-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "CSV Controller",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    BibleVerse.create!(book: "Genesis", chapter: 1, verse: 1, text: "In the beginning", testament: "OT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 16, text: "For God so loved", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 17, text: "For God sent not", testament: "NT")
    BibleVerse.create!(book: "John", chapter: 3, verse: 18, text: "He that believeth", testament: "NT")
    BibleVerse.create!(book: "Acts", chapter: 8, verse: 24, text: "Then answered Simon", testament: "NT")
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "csv tab renders file and paste fields" do
    get bulk_upload_hub_path(tab: "csv")

    assert_response :success
    assert_select "input[type=file]#csv_file"
    assert_select "textarea#csv_text"
    assert_select "form[action=?]", csv_import_path
  end

  test "imports comments from uploaded csv" do
    assert_difference -> { Comment.count }, 3 do
      post csv_import_path, params: {
        file: fixture_file_upload("csv_import/notes.csv", "text/csv")
      }
    end

    assert_redirected_to bulk_upload_hub_path(tab: "csv")
    follow_redirect!
    assert_match(/Imported 3 comments/, flash[:notice])
  end

  test "imports comments from pasted csv text" do
    csv = <<~CSV
      verse,comment
      Genesis 1:1,Pasted beginning
    CSV

    assert_difference -> { Comment.count }, 1 do
      post csv_import_path, params: { csv_text: csv }
    end

    assert_redirected_to bulk_upload_hub_path(tab: "csv")
    follow_redirect!
    assert_match(/Imported 1 comment/, flash[:notice])
    assert_equal "Pasted beginning", Comment.last.content.to_plain_text.strip
  end

  test "prefers an uploaded file over pasted text" do
    assert_difference -> { Comment.count }, 3 do
      post csv_import_path, params: {
        file: fixture_file_upload("csv_import/notes.csv", "text/csv"),
        csv_text: "verse,comment\nGenesis 1:1,This pasted row should be ignored"
      }
    end

    assert_redirected_to bulk_upload_hub_path(tab: "csv")
    texts = Comment.where(user: @user).map { |comment| comment.content.to_plain_text.strip }
    assert_includes texts, "In the beginning God created"
    refute_includes texts, "This pasted row should be ignored"
  end

  test "skips csv duplicates on re-import" do
    post csv_import_path, params: {
      file: fixture_file_upload("csv_import/notes.csv", "text/csv")
    }

    assert_no_difference -> { Comment.count } do
      post csv_import_path, params: {
        file: fixture_file_upload("csv_import/notes.csv", "text/csv")
      }
    end

    assert_redirected_to bulk_upload_hub_path(tab: "csv")
    follow_redirect!
    assert_match(/skipped 3 duplicates/, flash[:notice])
  end

  test "requires a csv file or pasted text" do
    post csv_import_path, params: {}

    assert_response :unprocessable_entity
    assert_match(/Attach a CSV file or paste CSV text/, flash[:alert])
  end

  test "rejects a non-csv upload" do
    post csv_import_path, params: {
      file: fixture_file_upload("sample.pdf", "application/pdf")
    }

    assert_response :unprocessable_entity
    assert_match(/Upload a \.csv file/, flash[:alert])
  end

  test "shows row failures for unparseable verses" do
    post csv_import_path, params: {
      csv_text: "verse,comment\nNotABook 1:1,Broken row"
    }

    assert_response :unprocessable_entity
    assert_match(/row failed/, flash[:alert])
    assert_match(/Could not parse/, response.body)
  end
end
