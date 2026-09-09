require "test_helper"

class Admin::JobsTest < ActionDispatch::IntegrationTest
  test "admins can view the job monitor" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    get "/admin/jobs"
    assert_response :success
    get "/admin/jobs/queues"
    assert_response :success

    admin.update!(role: :user)
    get "/admin/jobs"
    assert_redirected_to "/users/profile"
  end

  test "management actions reject requests without a CSRF token" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)
    previous_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post "/admin/jobs/pause_queue", params: { queue_name: "default" }
    assert_response :unprocessable_entity
    assert_not SolidQueue::Pause.exists?(queue_name: "default")
  ensure
    ActionController::Base.allow_forgery_protection = previous_protection
  end

  test "regular users cannot access the monitor or manage queues" do
    sign_in_as(users(:two))

    get "/admin/jobs"
    assert_redirected_to "/users/profile"
    post "/admin/jobs/pause_queue", params: { queue_name: "default" }
    assert_redirected_to "/users/profile"
    assert_not SolidQueue::Pause.exists?(queue_name: "default")
  end

  test "anonymous visitors must sign in before accessing the monitor" do
    get "/admin/jobs"
    assert_redirected_to "/session/new"
    post "/admin/jobs/pause_queue", params: { queue_name: "default" }
    assert_redirected_to "/session/new"
    assert_not SolidQueue::Pause.exists?(queue_name: "default")
  end
end
