require "test_helper"

class UserImports::CreateUserJobTest < ActiveJob::TestCase
  test "unexpected creation failures preserve progress and allow retrying the user" do
    import = UserImport.create!(admin: users(:one), file: {
      io: StringIO.new("name,email\nFirst,first@example.com\nSecond,second@example.com\n"),
      filename: "users.csv", content_type: "text/csv"
    })
    import.prepare!
    UserImports::CreateUserJob.perform_now(import, 1, "First", "first@example.com")
    previous_results = import.reload.results.deep_dup
    error = ActiveRecord::Deadlocked.new("Deadlock detected")
    import.define_singleton_method(:import_user!) { |*| raise error }

    assert_no_difference "User.count" do
      assert_same error, assert_raises(ActiveRecord::Deadlocked) {
        UserImports::CreateUserJob.perform_now(import, 2, "Second", "second@example.com")
      }
    end
    assert_predicate import.reload, :failed?
    assert_equal "Import interrupted. An administrator can retry the job in the job monitor.", import.error_message
    assert_equal previous_results, import.results
    assert_equal 1, import.imported_count
    assert_equal 0, import.failed_count

    import.singleton_class.remove_method(:import_user!)

    assert_difference "User.count", 1 do
      UserImports::CreateUserJob.perform_now(import, 2, "Second", "second@example.com")
    end
    assert_predicate import.reload, :completed?
    assert_equal 2, import.imported_count
    assert_nil import.error_message
    assert_equal previous_results.fetch("1"), import.results.fetch("1")
  end
end
