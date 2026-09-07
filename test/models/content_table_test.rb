require "test_helper"

class ContentTableTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "content-table-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Table Author",
      role: "contributor",
      otp_required_for_login: false,
      onboarding_completed_at: Time.current,
      contributor_agreement_accepted_at: Time.current
    )
  end

  test "valid with defaults" do
    table = ContentTable.new(
      user: @user,
      title: "Comparison",
      row_count: 2,
      column_count: 2,
      cells: [["A", "B"], ["C", "D"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    assert table.valid?
    assert table.header_row?
    assert_equal "#1e3228", table.style_with_defaults["header_bg"]
  end

  test "requires title" do
    table = ContentTable.new(user: @user, title: "", row_count: 1, column_count: 1, cells: [[""]])
    assert_not table.valid?
    assert_includes table.errors[:title], "can't be blank"
  end

  test "rejects oversized dimensions" do
    table = ContentTable.new(
      user: @user,
      title: "Huge",
      row_count: ContentTable::MAX_ROWS + 1,
      column_count: 2,
      cells: ContentTable.default_cells(ContentTable::MAX_ROWS + 1, 2)
    )
    assert_not table.valid?
    assert table.errors[:row_count].any?
  end

  test "rejects invalid style colors" do
    table = ContentTable.new(
      user: @user,
      title: "Bad color",
      row_count: 1,
      column_count: 1,
      cells: [["x"]],
      style: ContentTable::DEFAULT_STYLE.merge("header_bg" => "red")
    )
    assert_not table.valid?
    assert table.errors[:style].any?
  end

  test "normalizes cells to dimensions" do
    table = ContentTable.create!(
      user: @user,
      title: "Normalized",
      row_count: 2,
      column_count: 3,
      cells: [["only"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    assert_equal 2, table.cells.length
    assert_equal 3, table.cells.first.length
    assert_equal "only", table.cells[0][0]
    assert_equal "", table.cells[0][1]
  end

  test "is an action text attachable" do
    table = ContentTable.create!(
      user: @user,
      title: "Attachable",
      row_count: 1,
      column_count: 1,
      cells: [["cell"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    assert table.attachable_sgid.present?
    assert_equal "content_tables/editor", table.to_trix_content_attachment_partial_path
    assert_equal "content_tables/content_table", table.to_attachable_partial_path

    html = %Q(<action-text-attachment sgid="#{table.attachable_sgid}"></action-text-attachment>)
    content = ActionText::Content.new(html)
    assert_equal [table], content.attachables
  end

  test "can be stored on a note rich text body" do
    table = ContentTable.create!(
      user: @user,
      title: "In note",
      row_count: 1,
      column_count: 1,
      cells: [["Hello"]],
      style: ContentTable::DEFAULT_STYLE.dup
    )

    note = Note.create!(
      title: "Note with table",
      user: @user,
      status: "published",
      content: %Q(<div>See table</div><action-text-attachment sgid="#{table.attachable_sgid}"></action-text-attachment>)
    )

    assert_includes note.content.body.attachables, table
    rendered = note.content.to_s
    assert_match(/Hello/, rendered)
    assert_match(/content-table-embed/, rendered)
  end
end
