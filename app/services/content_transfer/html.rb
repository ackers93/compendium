# frozen_string_literal: true

module ContentTransfer
  module Html
    TABLE_CONTENT_TYPE = "application/vnd.actiontext.content_table"
    EXPORT_ID_ATTR = "data-content-table-export-id"

    module_function

    def export(html)
      transform(html) { |node| export_node(node) }
    end

    def import(html, id_map:)
      transform(html) { |node| import_node(node, id_map) }
    end

    def plain_text(html)
      ActionText::Content.new(html.to_s).to_plain_text.to_s.gsub(/\r\n?/, "\n").strip
    end

    def from_rich_text(rich_text)
      return "" unless rich_text&.body.present?

      export(rich_text.body.to_html)
    end

    def transform(html)
      return "" if html.blank?

      fragment = Nokogiri::HTML.fragment(html.to_s)
      fragment.css("action-text-attachment").each do |node|
        yield node
      end
      fragment.to_html
    end
    private_class_method :transform

    def export_node(node)
      existing_id = node[EXPORT_ID_ATTR]
      attachable = locate_attachable(node["sgid"])

      if attachable.is_a?(ContentTable) || table_attachment?(node)
        table_id = attachable.is_a?(ContentTable) ? attachable.id : existing_id
        if table_id.present?
          node[EXPORT_ID_ATTR] = table_id.to_s
          node["content-type"] = TABLE_CONTENT_TYPE
          node.remove_attribute("sgid")
          return
        end
      end

      node.remove
    end
    private_class_method :export_node

    def import_node(node, id_map)
      source_id = node[EXPORT_ID_ATTR].presence || extract_table_id(node)
      unless source_id
        node.remove
        return
      end

      local_id = id_map.lookup("ContentTable", source_id)
      table = local_id && ContentTable.find_by(id: local_id)
      unless table
        node.remove
        return
      end

      node["sgid"] = table.attachable_sgid.to_s
      node["content-type"] = table.attachable_content_type
      node.remove_attribute(EXPORT_ID_ATTR)
    end
    private_class_method :import_node

    def table_attachment?(node)
      node["content-type"].to_s == TABLE_CONTENT_TYPE || node[EXPORT_ID_ATTR].present?
    end
    private_class_method :table_attachment?

    def extract_table_id(node)
      node[EXPORT_ID_ATTR]
    end
    private_class_method :extract_table_id

    def locate_attachable(sgid)
      return nil if sgid.blank?

      ActionText::Attachable.from_attachable_sgid(sgid)
    rescue StandardError
      nil
    end
    private_class_method :locate_attachable
  end
end
