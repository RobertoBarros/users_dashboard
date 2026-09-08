require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "dashboard requires login and becomes inaccessible after logout" do
    get dashboard_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select "a[href=?]", new_registration_path, count: 0

    assert_difference "Session.count", -1 do
      delete session_path
    end
    get dashboard_path
    assert_redirected_to new_session_path
  end
end
