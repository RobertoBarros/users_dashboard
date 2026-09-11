require "application_system_test_case"

class AdminWorkflowsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    users(:one).update!(role: :admin)
    clear_enqueued_jobs

    visit new_session_path
    fill_in "Email", with: users(:one).email_address
    fill_in "Password", with: "password"
    click_button "Log in"
    assert_current_path admin_dashboard_path
  end

  test "editing a user validates input and refreshes another dashboard" do
    observer = open_new_window
    within_window observer do
      visit admin_dashboard_path
      assert_selector "turbo-cable-stream-source[connected]", visible: :all
    end

    within "#user_#{users(:two).id}" do
      click_on "Edit"
      fill_in "Full name", with: ""
      click_on "Save changes"
      assert_text "can't be blank"

      fill_in "Full name", with: "Updated User"
      perform_enqueued_jobs do
        click_on "Save changes"
        assert_text "Updated User"
        assert_no_button "Save changes"
      end
    end

    within_window observer do
      assert_selector "#user_#{users(:two).id}", text: "Updated User"
    end
  end

  test "uploading a CSV displays job progress and results without reloading" do
    visit admin_user_imports_path
    attach_file "CSV file", file_fixture("users.csv")
    click_on "Import users"

    assert_text "Waiting for a background worker."
    assert_selector "turbo-cable-stream-source[connected]", visible: :all

    # Drain queued jobs and run the row jobs and broadcasts they enqueue inline.
    perform_enqueued_jobs do
      perform_enqueued_jobs
    end

    within "#import_progress" do
      assert_text "Completed"
      assert_text "2 / 2 processed"
      assert_text "2 imported · 0 failed"
    end
    assert_selector "tbody tr", count: 2
    assert_text "import-one@example.com"
    assert_text "import-two@example.com"
  end
end
