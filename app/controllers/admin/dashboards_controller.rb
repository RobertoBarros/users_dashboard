class Admin::DashboardsController < Admin::BaseController
  include Pagy::Method

  def show
    @users_by_role = User.group(:role).count
    @pagy, @users = pagy(:offset, User.with_attached_avatar.order(created_at: :desc, id: :desc), limit: 25)
    redirect_to admin_dashboard_path(page: @pagy.last) if @pagy.page > @pagy.last
  end
end
