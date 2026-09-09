require "test_helper"

class Admin::UserImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:one)
    @admin.update!(role: :admin)
    sign_in_as(@admin)
  end

  test "admin uploads a CSV and returns to its persisted progress" do
    get admin_dashboard_path
    assert_select "a[href=?]", admin_user_imports_path, text: "Import users"
    get admin_user_imports_path
    assert_response :success

    assert_enqueued_with(job: UserImports::ProcessCsvJob) do
      post admin_user_imports_path, params: { user_import: { file: fixture_file_upload("users.csv", "text/csv") } }
    end
    import = @admin.user_imports.last
    assert_redirected_to admin_user_import_path(import)
    import.prepare!
    UserImports::CreateUserJob.perform_now(import, 1, "Import One", "import-one@example.com")

    get admin_user_imports_path
    assert_redirected_to admin_user_import_path(import)
    follow_redirect!
    assert_select "progress[value='1'][max='2']"
    assert_select "turbo-cable-stream-source"
    assert_select "#user_import_#{import.id}_result_1"

    perform_enqueued_jobs(only: UserImports::CreateUserJob) { UserImports::ProcessCsvJob.perform_now(import) }
    get admin_user_import_path(import)
    assert_select "progress[value='2'][max='2']"
    get admin_user_imports_path
    assert_response :success
    assert_select "a[href=?]", admin_user_import_path(import)
  end

  test "missing and non CSV files show an inline error without enqueuing" do
    [ nil, fixture_file_upload("avatar.png", "image/png") ].each do |file|
      assert_no_enqueued_jobs(only: UserImports::ProcessCsvJob) do
        assert_no_difference "UserImport.count" do
          post admin_user_imports_path, params: { user_import: { file: file } }
        end
      end
      assert_response :unprocessable_entity
      assert_select "#file_errors.text-error p"
    end
  end

  test "admins cannot view another admin's import" do
    import = UserImport.create!(admin: users(:two), file: fixture_file_upload("users.csv", "text/csv"))
    get admin_user_import_path(import)
    assert_response :not_found
  end

  test "regular users and anonymous visitors cannot view or create imports" do
    import = UserImport.create!(admin: @admin, file: fixture_file_upload("users.csv", "text/csv"))
    sign_in_as(users(:two))
    [ users_profile_path, new_session_path ].each do |destination|
      get admin_user_imports_path
      assert_redirected_to destination
      get admin_user_import_path(import)
      assert_redirected_to destination
      assert_no_difference "UserImport.count" do
        post admin_user_imports_path, params: { user_import: { file: fixture_file_upload("users.csv", "text/csv") } }
      end
      assert_redirected_to destination
      delete session_path
    end
  end
end
