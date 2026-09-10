require "test_helper"

class UserImportTest < ActiveSupport::TestCase
  test "accepts CSV files up to 5 MB and rejects larger files" do
    import = UserImport.new(admin: users(:one))
    import.file = { io: StringIO.new("a" * 5.megabytes), filename: "users.csv", content_type: "text/csv" }
    assert_predicate import, :valid?

    import.file = { io: StringIO.new("a" * (5.megabytes + 1)), filename: "users.csv", content_type: "text/csv" }
    assert_not import.save
    assert_includes import.errors[:file], "must be smaller than 5 MB"
    assert_not import.persisted?
  end

  test "database email conflicts are recorded as row failures and remaining users can be imported" do
    import = UserImport.create!(admin: users(:one), file: {
      io: StringIO.new("name,email\nDuplicate,new@example.com\nNext,next@example.com\n"),
      filename: "users.csv", content_type: "text/csv"
    })
    import.prepare!
    existing_email = users(:one).email_address
    # Trigger a real unique-index violation after the email validation has passed.
    conflict = ->(user) { user.email_address = existing_email if user.email_address == "new@example.com" }
    User.set_callback(:validation, :after, conflict)

    begin
      assert_no_difference "User.count" do
        import.import_user!(1, "Duplicate", "new@example.com")
      end
    ensure
      User.skip_callback(:validation, :after, conflict)
    end

    assert_predicate import.reload, :processing?
    assert_equal 0, import.imported_count
    assert_equal 1, import.failed_count
    result = import.results.fetch("1")
    assert_equal "failed", result.fetch("status")
    assert_includes result.fetch("error_message"), "has already been taken"

    assert_difference "User.count", 1 do
      import.import_user!(2, "Next", "next@example.com")
    end
    assert_predicate import.reload, :completed?
    assert_equal 1, import.imported_count
    assert_equal 1, import.failed_count
    assert_equal result, import.results.fetch("1")
    assert_equal "imported", import.results.fetch("2").fetch("status")
  end
end
