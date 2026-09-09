require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "dashboard refresh is broadcast after creation, role change and deletion" do
    user = users(:one).dup
    user.email_address = "new@example.com"
    user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")

    assert_dashboard_refresh { user.save! }
    assert_dashboard_refresh { user.update!(role: :admin) }
    assert_dashboard_refresh { user.destroy! }
  end

  test "profile changes broadcast a dashboard refresh" do
    user = users(:one)
    assert_dashboard_refresh { user.update!(full_name: "Updated Name") }
    assert_dashboard_refresh { user.update!(email_address: "updated@example.com") }
    assert_dashboard_refresh do
      user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "updated.png", content_type: "image/png")
    end
  end

  test "updates broadcast a refresh only to the changed user's profile" do
    user = users(:one)
    other_stream = "#{users(:two).to_gid_param}:profile"

    assert_no_broadcasts(other_stream) do
      messages = capture_broadcasts("#{user.to_gid_param}:profile") do
        user.update!(full_name: "Updated Name", email_address: "updated@example.com", role: :admin,
          password: "new-password", password_confirmation: "new-password")
      end
      assert_equal 1, messages.size
      stream = Nokogiri::HTML.fragment(messages.first)
      assert_equal "refresh", stream.at_css("turbo-stream")["action"]
    end
  end

  test "invalid updates do not broadcast a profile refresh" do
    user = users(:one)

    assert_no_broadcasts("#{user.to_gid_param}:profile") do
      assert_not user.update(full_name: "")
    end
  end

  test "full name is required for new and existing users" do
    new_user = User.new(email_address: "new@example.com", password: "password")

    [ new_user, users(:one) ].each do |user|
      [ nil, "", "   " ].each do |full_name|
        user.full_name = full_name
        assert_not user.save
        assert user.errors.added?(:full_name, :blank)
      end
    end
  end

  test "avatar is optional for new and existing users" do
    new_user = User.new(full_name: "Alex Morgan", email_address: "new@example.com", password: "password")

    [ new_user, users(:one) ].each do |user|
      user.avatar = nil
      assert user.save
    end
  end

  test "avatar rejects files that are not supported images" do
    user = users(:one)
    user.avatar = { io: StringIO.new("plain text"), filename: "avatar.txt", content_type: "text/plain" }

    assert user.invalid?
    assert_includes user.errors[:avatar], "must be a JPEG, PNG, GIF, or WebP image"
  end

  test "new users have the user role by default" do
    assert_equal "user", User.new.role
  end

  test "role must be user or admin" do
    user = users(:one)

    %w[user admin].each do |role|
      user.role = role
      assert user.valid?
    end

    [ nil, "manager" ].each do |role|
      user.role = role
      assert user.invalid?
      assert user.errors.added?(:role, :inclusion, value: role)
    end
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  private
    def assert_dashboard_refresh(&block)
      messages = capture_broadcasts("admin_dashboard", &block)
      assert_equal 1, messages.size
      stream = Nokogiri::HTML.fragment(messages.first)
      assert_equal "refresh", stream.at_css("turbo-stream")["action"]
    end
end
