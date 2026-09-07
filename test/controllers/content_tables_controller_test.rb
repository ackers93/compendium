require "test_helper"

class ContentTablesControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!

    @user = User.create!(
      email: "ct-user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Table Owner",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @other = User.create!(
      email: "ct-other-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Other Owner",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
    @table = ContentTable.create!(
      user: @user,
      title: "My Table",
      row_count: 2,
      column_count: 2,
      cells: [["H1", "H2"], ["A", "B"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "index lists own tables as html and json" do
    get content_tables_path
    assert_response :success
    assert_match "My Table", response.body

    get content_tables_path(format: :json)
    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload.length
    assert_equal "My Table", payload.first["title"]
  end

  test "create saves table for current user" do
    assert_difference -> { ContentTable.count }, 1 do
      post content_tables_path, params: {
        content_table: {
          title: "New Grid",
          row_count: 2,
          column_count: 2,
          cells: [["A", "B"], ["C", "D"]].to_json,
          style: ContentTable::DEFAULT_STYLE.to_json
        }
      }
    end

    table = ContentTable.order(:id).last
    assert_equal @user, table.user
    assert_equal "New Grid", table.title
    assert_redirected_to content_table_path(table)
  end

  test "update changes cells and style" do
    patch content_table_path(@table), params: {
      content_table: {
        title: "Updated Table",
        row_count: 1,
        column_count: 1,
        cells: [["Only"]].to_json,
        style: ContentTable::DEFAULT_STYLE.merge("header_row" => false, "show_title" => false).to_json
      }
    }

    assert_redirected_to content_table_path(@table)
    @table.reload
    assert_equal "Updated Table", @table.title
    assert_equal [["Only"]], @table.cells
    assert_not @table.header_row?
  end

  test "destroy removes own table" do
    assert_difference -> { ContentTable.count }, -1 do
      delete content_table_path(@table)
    end
    assert_redirected_to content_tables_path
  end

  test "destroy forbids other users table" do
    other_table = ContentTable.create!(
      user: @other,
      title: "Other",
      row_count: 1,
      column_count: 1,
      cells: [["x"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    assert_no_difference -> { ContentTable.count } do
      delete content_table_path(other_table)
    end
  end

  test "attachable returns sgid payload for owner" do
    get attachable_content_table_path(@table), as: :json
    assert_response :success

    payload = JSON.parse(response.body)
    assert payload["sgid"].present?
    assert_equal "application/vnd.actiontext.content_table", payload["contentType"]
    assert_equal "My Table", payload["filename"]
    assert_match(/content-table-trix-preview/, payload["content"])
  end

  test "attachable forbids other users table" do
    other_table = ContentTable.create!(
      user: @other,
      title: "Secret",
      row_count: 1,
      column_count: 1,
      cells: [["x"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    get attachable_content_table_path(other_table), as: :json
    assert_response :redirect
  end

  test "new shows trix banner when from=trix" do
    get new_content_table_path(from: "trix")
    assert_response :success
    assert_match(/return to your other tab/, response.body)
  end
end
