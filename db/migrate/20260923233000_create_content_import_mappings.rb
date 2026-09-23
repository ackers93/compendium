class CreateContentImportMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :content_import_mappings do |t|
      t.string :source, null: false
      t.string :record_type, null: false
      t.bigint :source_id, null: false
      t.bigint :local_id, null: false

      t.timestamps
    end

    add_index :content_import_mappings,
              [:source, :record_type, :source_id],
              unique: true,
              name: "index_content_import_mappings_on_source_type_and_id"
  end
end
