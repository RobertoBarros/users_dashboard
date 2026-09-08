require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "dashboard requires login and becomes inaccessible after logout" do
    get admin_dashboard_path
    assert_redirected_to new_session_path

    users(:one).update!(role: :admin)
    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to admin_dashboard_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select "a[href=?]", users_profile_path, text: "Profile"
    assert_select "a[href=?]", new_registration_path, count: 0

    assert_difference "Session.count", -1 do
      delete session_path
    end
    get admin_dashboard_path
    assert_redirected_to new_session_path
  end

  test "regular users cannot access the admin dashboard" do
    sign_in_as(users(:one))

    get admin_dashboard_path

    assert_redirected_to users_profile_path
  end
end
