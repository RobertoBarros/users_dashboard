require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to users_profile_path
    assert cookies[:session_id]

    follow_redirect!
    assert_response :success
  end

  test "session cookie follows the secure cookies configuration" do
    original = Rails.configuration.x.secure_cookies

    [ true, false ].each do |secure|
      Rails.configuration.x.secure_cookies = secure
      https!(secure)
      post session_path, params: { email_address: @user.email_address, password: "password" }

      cookie = Array(response.headers["set-cookie"]).find { |value| value.start_with?("session_id=") }
      assert cookie
      assert_equal secure, cookie.match?(/; secure/i)
    end
  ensure
    Rails.configuration.x.secure_cookies = original
  end

  test "admin signs in to the admin dashboard" do
    @user.update!(role: :admin)

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to admin_dashboard_path
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
