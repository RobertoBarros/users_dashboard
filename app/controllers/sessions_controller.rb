class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      @user = User.new(email_address: params[:email_address])
      @user.errors.add(:email_address, :blank) if @user.email_address.blank?
      @user.errors.add(:password, :blank) if params[:password].blank?
      if @user.errors.empty?
        @user.errors.add(:password, "or email address is incorrect.")
      end
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
