require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(role: :admin)
    @user = users(:two)
    sign_in_as(@admin)
  end

  test "admin opens and cancels inline editing" do
    get admin_dashboard_path
    assert_select "#user_#{@user.id} a[data-turbo-stream][href=?]", edit_admin_user_path(@user)

    get edit_admin_user_path(@user), as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=replace][target=user_#{@user.id}]" do
      assert_select "form[action=?]", admin_user_path(@user) do
        %w[full_name email_address role password password_confirmation avatar].each do |attribute|
          assert_select "[name=?]", "user[#{attribute}]"
        end
        assert_select "a[data-turbo-stream][href=?]", admin_user_path(@user), text: "Cancel"
      end
    end

    get admin_user_path(@user), as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[target=user_#{@user.id}]" do
      assert_select "tr#user_#{@user.id}"
      assert_select "form", count: 0
    end
  end

  test "admin updates all editable user data" do
    avatar = fixture_file_upload("avatar.png", "image/png")

    patch admin_user_path(@user), params: { user: {
      full_name: "Updated User", email_address: "updated@example.com", role: "admin",
      password: "new-password", password_confirmation: "new-password", avatar: avatar
    } }, as: :turbo_stream

    assert_response :success
    @user.reload
    assert_equal "Updated User", @user.full_name
    assert_equal "updated@example.com", @user.email_address
    assert_predicate @user, :admin?
    assert @user.authenticate("new-password")
    assert @user.avatar.attached?
    assert_select "turbo-stream[target=user_#{@user.id}]", text: /Updated User/
    assert_select "turbo-stream[target=user_statistics]"
  end

  test "blank password fields preserve the password" do
    digest = @user.password_digest

    patch admin_user_path(@user), params: { user: {
      full_name: "Updated User", password: "", password_confirmation: ""
    } }, as: :turbo_stream

    assert_response :success
    assert_equal digest, @user.reload.password_digest
    assert_equal "Updated User", @user.full_name
  end

  test "invalid data renders errors under the corresponding inputs without saving" do
    avatar_id = @user.avatar.blob_id

    patch admin_user_path(@user), params: { user: {
      full_name: "", email_address: @admin.email_address, role: "invalid",
      password: "short", password_confirmation: "different",
      avatar: fixture_file_upload("../users.yml", "text/plain")
    } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace][target=user_#{@user.id}]" do
      %w[full_name email_address role password password_confirmation avatar].each do |attribute|
        assert_select "[name=?][aria-invalid=true]", "user[#{attribute}]" do |inputs|
          assert_includes inputs.first["aria-describedby"].split, "#{attribute}_errors_user_#{@user.id}"
        end
        assert_select "##{attribute}_errors_user_#{@user.id}.text-error p", minimum: 1
      end
      assert_select "#full_name_errors_user_#{@user.id}", text: /can't be blank/
      assert_select "input[name=?][value]", "user[password]", count: 0
    end
    assert_equal "Taylor Smith", @user.reload.full_name
    assert_equal "two@example.com", @user.email_address
    assert_predicate @user, :user?
    assert @user.authenticate("password")
    assert_equal avatar_id, @user.avatar.blob_id
  end

  test "admin can change their own role and loses admin access" do
    patch admin_user_path(@admin), params: { user: { role: "user" } }, as: :turbo_stream

    assert_redirected_to users_profile_path
    assert_predicate @admin.reload, :user?
    get edit_admin_user_path(@user), as: :turbo_stream
    assert_redirected_to users_profile_path
  end

  test "regular users cannot view edit forms or update users" do
    sign_in_as(@user)

    get edit_admin_user_path(@admin), as: :turbo_stream
    assert_redirected_to users_profile_path
    get admin_user_path(@admin), as: :turbo_stream
    assert_redirected_to users_profile_path
    patch admin_user_path(@user), params: { user: { role: "admin" } }, as: :turbo_stream
    assert_redirected_to users_profile_path
    assert_predicate @user.reload, :user?
  end

  test "anonymous visitors cannot edit users" do
    delete session_path

    get edit_admin_user_path(@user)
    assert_redirected_to new_session_path
    patch admin_user_path(@user), params: { user: { role: "admin" } }
    assert_redirected_to new_session_path
    assert_predicate @user.reload, :user?
  end
end
