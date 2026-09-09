class Admin::UsersController < Admin::BaseController
  before_action :set_user

  def show
    respond_to do |format|
      format.html { redirect_to admin_dashboard_path }
      format.turbo_stream
    end
  end

  def edit
  end

  def update
    attributes = params.expect(user: %i[ full_name email_address role password password_confirmation avatar ])
    if attributes[:password].blank? && attributes[:password_confirmation].blank?
      attributes = attributes.except(:password, :password_confirmation)
    end

    if @user.update(attributes)
      if @user == Current.user && !@user.admin?
        redirect_to users_profile_path, status: :see_other
      else
        respond_to do |format|
          format.html { redirect_to admin_dashboard_path, status: :see_other }
          format.turbo_stream { render :show }
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
