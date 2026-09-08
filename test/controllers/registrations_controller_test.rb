require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up starts a session and opens the profile" do
    get root_path
    assert_select "a[href=?]", new_session_path
    assert_select "a[href=?]", new_registration_path

    get new_registration_path
    assert_response :success
    assert_select "input[name='user[full_name]']"
    assert_select "input[type=file][name='user[avatar]'][required]"

    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png"), full_name: "Alex Morgan", email_address: " NEW@example.com ", password: "secure-password", password_confirmation: "secure-password" } }
    end

    assert_redirected_to users_profile_path
    follow_redirect!
    assert_response :success
    assert_select "dd", text: "new@example.com"
    assert_select "dd", text: "Alex Morgan"
    assert_select ".avatar img[alt=?]", "Alex Morgan's avatar"
    assert User.find_by!(email_address: "new@example.com").avatar.attached?
  end

  test "registration requires an avatar" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: { user: { full_name: "Alex Morgan", email_address: "new@example.com", password: "secure-password", password_confirmation: "secure-password" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Avatar is required/
  end

  test "invalid registration does not create a user or session" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: { user: { email_address: "invalid", password: "short", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
  end

  test "existing email cannot be registered again" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png"), full_name: "Alex Morgan", email_address: " ONE@example.com ", password: "secure-password", password_confirmation: "secure-password" } }
    end

    assert_response :unprocessable_entity
  end
end
