class StoreResultsOnUserImports < ActiveRecord::Migration[8.1]
  def up
    add_column :user_imports, :results, :jsonb, null: false, default: {}

    execute <<~SQL
      UPDATE user_imports
      SET results = completed.results
      FROM (
        SELECT user_import_id, jsonb_object_agg(position::text, jsonb_build_object(
          'position', position, 'full_name', full_name, 'email_address', email_address,
          'status', status, 'error_message', error_message
        )) AS results
        FROM user_import_rows
        WHERE status != 'pending'
        GROUP BY user_import_id
      ) completed
      WHERE user_imports.id = completed.user_import_id
    SQL

    drop_table :user_import_rows
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Import rows have been replaced by results on user_imports."
  end
end
