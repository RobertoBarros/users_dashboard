require "test_helper"

class Users::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "profile requires authentication" do
    get users_profile_path
    assert_redirected_to new_session_path

    get edit_users_profile_path
    assert_redirected_to new_session_path

    patch users_profile_path, params: { user: { email_address: "changed@example.com" } }
    assert_redirected_to new_session_path
  end

  test "profile shows the signed in user and hides the admin dashboard link" do
    sign_in_as(users(:one))

    get users_profile_path

    assert_response :success
    assert_select "dd", text: users(:one).email_address
    assert_select "a[href=?]", edit_users_profile_path, text: "Edit profile"
    assert_select "input[name='user[email_address]']", count: 0
    assert_select "a[href=?]", admin_dashboard_path, count: 0
  end

  test "edit shows the signed in user's information" do
    user = users(:one)
    user.update!(full_name: "Alex Morgan")
    sign_in_as(user)

    get edit_users_profile_path

    assert_response :success
    assert_select "h1", "Edit profile"
    assert_select "input[name='user[full_name]'][value='Alex Morgan']"
    assert_select "input[name='user[email_address]'][value=?]", user.email_address
    assert_select "a[href=?]", users_profile_path, text: "Cancel"
  end

  test "updates only the signed in user and preserves password when blank" do
    user = users(:one)
    other_user = users(:two)
    sign_in_as(user)

    patch users_profile_path, params: { id: other_user.id, user: {
      id: other_user.id, full_name: "Alex Morgan", email_address: "updated@example.com", role: "admin",
      password: "", password_confirmation: ""
    } }

    assert_redirected_to users_profile_path
    assert_equal "updated@example.com", user.reload.email_address
    assert_equal "Alex Morgan", user.full_name
    assert user.user?
    assert user.authenticate("password")
    assert_equal "two@example.com", other_user.reload.email_address
  end

  test "admin can edit their own profile" do
    user = users(:one)
    user.update!(role: :admin)
    sign_in_as(user)

    get edit_users_profile_path
    assert_response :success
    assert_select "a[href=?]", admin_dashboard_path

    patch users_profile_path, params: { user: { email_address: "admin-updated@example.com" } }

    assert_redirected_to users_profile_path
    assert_equal "admin-updated@example.com", user.reload.email_address
    assert user.admin?
  end

  test "updates password with matching confirmation" do
    user = users(:one)
    sign_in_as(user)

    patch users_profile_path, params: { user: { password: "new-password", password_confirmation: "new-password" } }

    assert_redirected_to users_profile_path
    assert user.reload.authenticate("new-password")
  end

  test "invalid changes display errors without updating the profile" do
    user = users(:one)
    sign_in_as(user)

    patch users_profile_path, params: { user: {
      email_address: "invalid", password: "short", password_confirmation: "different"
    } }

    assert_response :unprocessable_entity
    assert_select "h1", "Edit profile"
    assert_select "[role=alert]"
    assert_equal "one@example.com", user.reload.email_address
    assert user.authenticate("password")
  end
end
