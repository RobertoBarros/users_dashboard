require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "dashboard lists every user newest first in pages of 25" do
    users(:one).update!(role: :admin)
    sign_in_as(users(:one))
    User.insert_all!(24.times.map do |index|
      { full_name: "User #{index}", email_address: "paginated#{index}@example.com",
        password_digest: users(:one).password_digest, created_at: (index + 1).days.ago }
    end)
    ordered_users = User.order(created_at: :desc, id: :desc).to_a

    get admin_dashboard_path, params: { limit: 100 }

    assert_response :success
    assert_select "#users tbody tr", count: 25
    assert_select "#users tbody tr td:nth-child(2)" do |cells|
      assert_equal ordered_users.first(25).map(&:email_address), cells.map(&:text)
    end
    assert_select "#users td", text: ordered_users.last.email_address, count: 0
    assert_select "a[rel=next]" do |links|
      get links.first["href"]
    end

    assert_response :success
    assert_select "#users tbody tr", count: 1
    assert_select "#users td", text: ordered_users.last.email_address
    assert_select "a[rel=prev]"
    assert_select "a[rel=next]", count: 0

    ordered_users.last.destroy!
    get admin_dashboard_path, params: { page: 2 }

    assert_redirected_to admin_dashboard_path(page: 1)
    follow_redirect!
    assert_select "#users tbody tr", count: 25
  end

  test "dashboard shows total users and counts for every role with a live stream" do
    users(:one).update!(role: :admin)
    sign_in_as(users(:one))

    get admin_dashboard_path

    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name]"
    assert_select "meta[name=turbo-refresh-method][content=morph]"
    assert_select "meta[name=turbo-refresh-scroll][content=preserve]"
    assert_select "tr#user_#{users(:one).id}", text: /#{Regexp.escape(users(:one).email_address)}/
    assert_select "#total_users", "2"
    assert_select "#user_count", "1"
    assert_select "#admin_count", "1"

    users(:two).update!(role: :admin)
    get admin_dashboard_path

    assert_select "#total_users", "2"
    assert_select "#user_count", "0"
    assert_select "#admin_count", "2"
  end

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
