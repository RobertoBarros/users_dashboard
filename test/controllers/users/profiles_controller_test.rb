require "test_helper"

class Users::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "profile requires authentication" do
    get users_profile_path
    assert_redirected_to new_session_path

    get edit_users_profile_path
    assert_redirected_to new_session_path

    patch users_profile_path, params: { user: { email_address: "changed@example.com" } }
    assert_redirected_to new_session_path

    assert_no_difference "User.count" do
      delete users_profile_path
    end
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
    assert_select "form[action=?][data-turbo-confirm]", users_profile_path do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", "Delete profile"
    end
  end

  test "deletes only the signed in profile and all its sessions" do
    user = users(:one)
    other_user = users(:two)
    user.sessions.create!
    sign_in_as(user)

    assert_difference "User.count", -1 do
      assert_difference "Session.count", -2 do
        delete users_profile_path, params: { id: other_user.id }
      end
    end

    assert_redirected_to root_path
    assert_equal "Profile deleted.", flash[:success]
    assert_not User.exists?(user.id)
    assert User.exists?(other_user.id)
    assert_empty cookies[:session_id]

    get users_profile_path
    assert_redirected_to new_session_path
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
    avatar_id = user.avatar.blob_id
    other_user = users(:two)
    sign_in_as(user)

    patch users_profile_path, params: { id: other_user.id, user: {
      id: other_user.id, full_name: "Alex Morgan", email_address: "updated@example.com", role: "admin",
      password: "", password_confirmation: ""
    } }

    assert_redirected_to users_profile_path
    assert_equal "updated@example.com", user.reload.email_address
    assert_equal "Alex Morgan", user.full_name
    assert_equal avatar_id, user.avatar.blob_id
    assert user.user?
    assert user.authenticate("password")
    assert_equal "two@example.com", other_user.reload.email_address
  end

  test "updates a profile without an avatar" do
    user = users(:one)
    user.avatar.purge
    sign_in_as(user)

    get edit_users_profile_path
    assert_response :success
    assert_select "input[type=file][name='user[avatar]']:not([required])"

    patch users_profile_path, params: { user: { full_name: "Alex Morgan" } }

    assert_redirected_to users_profile_path
    assert_equal "Alex Morgan", user.reload.full_name
    follow_redirect!
    assert_select ".avatar.avatar-placeholder span", text: "AM"
  end

  test "replaces the avatar from the profile" do
    user = users(:one)
    previous_avatar_id = user.avatar.blob_id
    sign_in_as(user)

    patch users_profile_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }

    assert_redirected_to users_profile_path
    assert_not_equal previous_avatar_id, user.reload.avatar.blob_id
    follow_redirect!
    assert_select ".avatar img[alt=?]", "#{user.full_name}'s avatar"
  end

  test "invalid avatar preserves the existing avatar" do
    user = users(:one)
    previous_avatar_id = user.avatar.blob_id
    sign_in_as(user)

    patch users_profile_path, params: { user: { avatar: fixture_file_upload("../users.yml", "text/plain") } }

    assert_response :unprocessable_entity
    assert_select "#avatar_errors_user_#{user.id}.text-error", text: /Avatar must be/
    assert_equal previous_avatar_id, user.reload.avatar.blob_id
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
    %w[email_address password password_confirmation].each do |attribute|
      assert_select "input[name='user[#{attribute}]'].input-error[aria-invalid=true]"
      assert_select "##{attribute}_errors_user_#{user.id}.text-error p"
    end
    assert_equal "one@example.com", user.reload.email_address
    assert user.authenticate("password")
  end
end
