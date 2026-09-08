class Users::ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    attributes = params.expect(user: %i[ full_name email_address password password_confirmation ])
    if attributes[:password].blank? && attributes[:password_confirmation].blank?
      attributes = attributes.except(:password, :password_confirmation)
    end

    if @user.update(attributes)
      redirect_to users_profile_path, success: "Profile updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = Current.user
    end
end
