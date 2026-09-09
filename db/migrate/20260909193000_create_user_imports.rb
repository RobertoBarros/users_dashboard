class CreateUserImports < ActiveRecord::Migration[8.1]
  def change
    create_table :user_imports do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.integer :total_count, null: false, default: 0
      t.integer :imported_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.text :error_message
      t.timestamps
    end

    create_table :user_import_rows do |t|
      t.references :user_import, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :full_name
      t.string :email_address
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.datetime :processed_at
      t.timestamps
      t.index [ :user_import_id, :position ], unique: true
    end
  end
end
