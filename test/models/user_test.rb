require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "dashboard statistics are broadcast after creation, role change and deletion" do
    user = users(:one).dup
    user.email_address = "new@example.com"
    user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")

    assert_statistics_broadcast(total: 3, users: 3, admins: 0) { user.save! }
    assert_statistics_broadcast(total: 3, users: 2, admins: 1) { user.update!(role: :admin) }
    assert_statistics_broadcast(total: 2, users: 2, admins: 0) { user.destroy! }
  end

  test "profile changes do not broadcast dashboard statistics" do
    assert_no_broadcasts "admin_dashboard" do
      users(:one).update!(full_name: "Updated Name")
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

  test "avatar is required for new and existing users" do
    [ User.new, users(:one) ].each do |user|
      user.avatar = nil
      assert user.invalid?
      assert_includes user.errors[:avatar], "is required"
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
    def assert_statistics_broadcast(total:, users:, admins:, &block)
      messages = capture_broadcasts("admin_dashboard", &block)
      assert_equal 1, messages.size
      stream = Nokogiri::HTML.fragment(messages.first)
      assert_equal "replace", stream.at_css("turbo-stream")["action"]
      assert_equal "user_statistics", stream.at_css("turbo-stream")["target"]
      assert_equal total.to_s, stream.at_css("#total_users").text
      assert_equal users.to_s, stream.at_css("#user_count").text
      assert_equal admins.to_s, stream.at_css("#admin_count").text
    end
end
