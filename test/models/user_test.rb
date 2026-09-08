require "test_helper"

class UserTest < ActiveSupport::TestCase
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
end
