require "test_helper"

class Admin::ContentTransfersControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @admin = create_user("admin", role: "admin")
    @contributor = create_user("contrib", role: "contributor")
    @viewer = create_user("viewer", role: "viewer")
    @author = create_user("author")
    Note.create!(
      user: @author,
      title: "Exportable",
      status: "published",
      content: "<div>Keep this</div>"
    )
  end

  teardown do
    Warden.test_reset!
  end

  test "admin can view export import page" do
    login_as @admin, scope: :user
    get admin_content_transfer_path

    assert_response :success
    assert_select "h1", text: "Export / Import"
    assert_select "a[href=?]", export_admin_content_transfer_path(type: "notes")
    assert_select "form[action=?]", import_admin_content_transfer_path
  end

  test "contributor cannot view export import page" do
    login_as @contributor, scope: :user
    get admin_content_transfer_path

    assert_redirected_to root_path
    assert_match(/admin/i, flash[:alert])
  end

  test "viewer cannot export" do
    login_as @viewer, scope: :user
    get export_admin_content_transfer_path(type: "notes")

    assert_redirected_to root_path
  end

  test "admin can download notes json" do
    login_as @admin, scope: :user
    get export_admin_content_transfer_path(type: "notes")

    assert_response :success
    assert_match(/attachment/, response.headers["Content-Disposition"].to_s)
    payload = JSON.parse(response.body)
    assert_equal "compendium.export", payload["format"]
    assert_equal "notes", payload["type"]
    assert payload["records"].any? { |row| row["title"] == "Exportable" }
  end

  test "admin can download all types as zip" do
    login_as @admin, scope: :user
    get export_admin_content_transfer_path(type: "all")

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_equal "PK", response.body[0, 2]
  end

  test "admin can import notes json and skip duplicates" do
    login_as @admin, scope: :user
    json = ContentTransfer.export("notes", source: "controller-test")

    post import_admin_content_transfer_path, params: {
      type: "notes",
      file: uploaded_json(json)
    }

    assert_redirected_to admin_content_transfer_path
    follow_redirect!
    assert_match(/skipped/i, flash[:notice])
    assert_equal 1, Note.where(title: "Exportable").count
  end

  test "import without a file shows an alert" do
    login_as @admin, scope: :user
    post import_admin_content_transfer_path, params: { type: "notes" }

    assert_redirected_to admin_content_transfer_path
    follow_redirect!
    assert_match(/JSON export file/, flash[:alert])
  end

  test "contributor cannot import" do
    login_as @contributor, scope: :user
    json = ContentTransfer.export("notes", source: "controller-test")

    post import_admin_content_transfer_path, params: {
      type: "notes",
      file: uploaded_json(json)
    }

    assert_redirected_to root_path
  end

  private

  def create_user(label, role: "contributor")
    User.create!(
      email: "#{label}-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: label.capitalize,
      role: role,
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      admin_onboarding_completed_at: role == "admin" ? Time.current : nil,
      contributor_agreement_accepted_at: Time.current
    )
  end

  def uploaded_json(json)
    file = Tempfile.new(["compendium", ".json"])
    file.write(json)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/json")
  end
end
