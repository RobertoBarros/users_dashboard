class ReplaceAdminWithRoleOnUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string, default: "user", null: false
    execute "UPDATE users SET role = 'admin' WHERE admin = TRUE"
    remove_column :users, :admin
  end

  def down
    add_column :users, :admin, :boolean, default: false, null: false
    execute "UPDATE users SET admin = TRUE WHERE role = 'admin'"
    remove_column :users, :role
  end
end
