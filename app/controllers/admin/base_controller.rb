class Admin::BaseController < ApplicationController
  before_action :require_admin

  private
    def require_admin
      redirect_to users_profile_path, alert: "You do not have access to this page." unless Current.user.admin?
    end
end
