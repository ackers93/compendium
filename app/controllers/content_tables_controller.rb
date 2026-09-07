class ContentTablesController < ApplicationController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_content_table, only: %i[show edit update destroy attachable]
  before_action :authorize_create!, only: %i[new create]
  before_action -> { authorize_edit!(@content_table) }, only: %i[edit update]
  before_action -> { authorize_delete!(@content_table) }, only: %i[destroy]
  before_action :authorize_attachable!, only: %i[attachable]

  def index
    @content_tables = scoped_tables.order(updated_at: :desc)

    if params[:search].present?
      query = "%#{params[:search].to_s.downcase}%"
      @content_tables = @content_tables.where("LOWER(title) LIKE ?", query)
    end

    respond_to do |format|
      format.html
      format.json do
        render json: @content_tables.map { |table| table_json(table) }
      end
    end
  end

  def show
  end

  def new
    @content_table = ContentTable.new(
      column_count: 3,
      row_count: 3,
      cells: ContentTable.default_cells(3, 3),
      style: ContentTable::DEFAULT_STYLE.dup
    )
  end

  def create
    @content_table = ContentTable.new(content_table_params)
    @content_table.user = current_user

    if @content_table.save
      redirect_to @content_table, notice: "Table was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @content_table.update(content_table_params)
      redirect_to @content_table, notice: "Table was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @content_table.destroy
    redirect_to content_tables_path, notice: "Table was successfully deleted."
  end

  def attachable
    content_html = render_to_string(
      partial: @content_table.to_trix_content_attachment_partial_path,
      locals: { content_table: @content_table },
      formats: [:html]
    )

    render json: {
      sgid: @content_table.attachable_sgid,
      contentType: @content_table.attachable_content_type,
      filename: @content_table.attachable_filename,
      previewable: true,
      content: content_html
    }
  end

  private

  def set_content_table
    @content_table = ContentTable.find(params[:id])
  end

  def scoped_tables
    if current_user.role_admin?
      ContentTable.includes(:user)
    else
      current_user.content_tables
    end
  end

  def authorize_attachable!
    return if current_user.role_admin?
    return if @content_table.user_id == current_user.id

    raise Authorizable::NotAuthorized, "You are not authorized to insert this table"
  end

  def content_table_params
    permitted = params.require(:content_table).permit(
      :title,
      :column_count,
      :row_count,
      :cells,
      :style
    )

    permitted[:cells] = parse_json_param(permitted[:cells]) if permitted.key?(:cells)
    permitted[:style] = parse_json_param(permitted[:style]) if permitted.key?(:style)
    permitted
  end

  def parse_json_param(value)
    return value if value.is_a?(Hash) || value.is_a?(Array)
    return {} if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError
    value
  end

  def table_json(table)
    {
      id: table.id,
      title: table.title,
      row_count: table.row_count,
      column_count: table.column_count,
      updated_at: table.updated_at.iso8601
    }
  end
end
