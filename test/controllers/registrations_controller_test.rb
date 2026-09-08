require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up starts a session and opens the profile" do
    get root_path
    assert_select "a[href=?]", new_session_path
    assert_select "a[href=?]", new_registration_path

    get new_registration_path
    assert_response :success

    assert_difference [ "User.count", "Session.count" ], 1 do
      post registration_path, params: { user: { email_address: " NEW@example.com ", password: "secure-password", password_confirmation: "secure-password" } }
    end

    assert_redirected_to users_profile_path
    follow_redirect!
    assert_response :success
    assert_select "input[name='user[email_address]'][value='new@example.com']"
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
      post registration_path, params: { user: { email_address: " ONE@example.com ", password: "secure-password", password_confirmation: "secure-password" } }
    end

    assert_response :unprocessable_entity
  end
end
