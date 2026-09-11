require "test_helper"

class UserImports::ProcessCsvJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  test "detects reversed columns and persists successes and validation failures with broadcasts" do
    import = build_import("email,name\nnew@example.com,New User\n NEW@EXAMPLE.COM ,Duplicate\ninvalid,Bad Email\nblank@example.com,\n")

    streams = capture_turbo_stream_broadcasts(import) do
      assert_difference "User.count", 1 do
        perform_import(import)
      end
    end

    assert_predicate import.reload, :completed?
    assert_equal [ 4, 1, 3 ], [ import.total_count, import.imported_count, import.failed_count ]
    assert_not_empty streams
    assert streams.all? { |stream| stream["action"] == "refresh" }
    assert_includes import.results.fetch("2").fetch("error_message"), "has already been taken"
    assert_includes import.results.fetch("3").fetch("error_message"), "is invalid"
    assert_includes import.results.fetch("4").fetch("error_message"), "can't be blank"
    user = User.find_by!(email_address: "new@example.com")
    assert_predicate user, :user?
    assert user.password_digest.present?

    assert_no_difference "User.count" do
      perform_import(import)
    end
  end

  test "accepts BOM headers quoted names and semicolon separators" do
    import = build_import("\uFEFFname;email\n\"Smith, Alex\";alex@example.com\n")
    perform_import(import)
    assert_predicate import.reload, :completed?
    assert_equal "Smith, Alex", User.find_by!(email_address: "alex@example.com").full_name
  end

  test "detects emails by content without headers in either order" do
    [ "First User,first@example.com\n", "second@example.com,Second User\n" ].each do |csv|
      import = build_import(csv)
      perform_import(import)
      assert_equal 1, import.reload.imported_count
    end
  end

  test "records invalid rows even when every email is invalid with a recognized header" do
    import = build_import("name,email\nBad User,invalid\n")
    perform_import(import)
    assert_predicate import.reload, :completed?
    assert_equal 1, import.failed_count
  end

  test "empty malformed ambiguous and invalid encoding files fail visibly without creating users" do
    [ "", "name,email\n", "\"unclosed,name\n", "Alice,Bob\n", "a@example.com,b@example.com\n", "name,email,role\nA,a@example.com,admin\n", "\xFF".b ].each do |csv|
      import = build_import(csv)
      assert_no_difference "User.count" do
        perform_import(import)
      end
      assert_predicate import.reload, :failed?
      assert import.error_message.present?
      assert_equal 0, import.results.size
    end
  end

  test "resuming an interrupted import preserves earlier results" do
    import = build_import("name,email\nFirst,first@example.com\nSecond,second@example.com\n")
    import.prepare!
    UserImports::CreateUserJob.perform_now(import, 1, "First", "first@example.com")
    import.update!(status: :failed, error_message: "Interrupted")

    assert_difference "User.count", 1 do
      perform_import(import)
    end
    assert_predicate import.reload, :completed?
    assert_equal 2, import.imported_count
    assert_equal 0, import.failed_count
    assert_nil import.error_message
  end

  test "preparation enqueues one job per pending row without importing users" do
    import = build_import("name,email\nFirst,first@example.com\nSecond,second@example.com\n")

    assert_no_difference "User.count" do
      assert_enqueued_jobs 2, only: UserImports::CreateUserJob do
        UserImports::ProcessCsvJob.perform_now(import)
      end
    end
    assert_predicate import.reload, :processing?
    assert_equal 0, import.processed_count

    assert_empty import.results
    UserImports::CreateUserJob.perform_now(import, 2, "Second", "second@example.com")
    assert_predicate import.reload, :processing?
    assert_equal 1, import.processed_count

    assert_no_difference "User.count" do
      UserImports::CreateUserJob.perform_now(import, 2, "Second", "second@example.com")
    end
    assert_equal 1, import.reload.processed_count

    UserImports::CreateUserJob.perform_now(import, 1, "First", "first@example.com")
    assert_predicate import.reload, :completed?
    assert_equal 2, import.processed_count
  end

  test "unexpected preparation failures are recorded and can be retried" do
    [ IOError.new("Storage unavailable"), ArgumentError.new("Invalid job arguments") ].each_with_index do |error, index|
      import = build_import("name,email\nFirst,first-#{index}@example.com\n")
      import.define_singleton_method(:prepare!) { raise error }

      assert_no_enqueued_jobs only: UserImports::CreateUserJob do
        assert_same error, assert_raises(error.class) { UserImports::ProcessCsvJob.perform_now(import) }
      end
      assert_predicate import.reload, :failed?
      assert_equal "Import interrupted. An administrator can retry the job in the job monitor.", import.error_message
      assert_empty import.results

      import.singleton_class.remove_method(:prepare!)

      assert_difference "User.count", 1 do
        perform_import(import)
      end
      assert_predicate import.reload, :completed?
      assert_equal 1, import.imported_count
      assert_nil import.error_message
    end
  end

  private
    def perform_import(import)
      perform_enqueued_jobs(only: [ UserImports::CreateUserJob, Turbo::Streams::BroadcastStreamJob ]) do
        UserImports::ProcessCsvJob.perform_now(import)
      end
    end

    def build_import(csv)
      UserImport.create!(admin: users(:one), file: { io: StringIO.new(csv), filename: "users.csv", content_type: "text/csv" })
    end
end
