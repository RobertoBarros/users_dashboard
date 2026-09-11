class Admin::UserImportsController < Admin::BaseController
  include Pagy::Method

  def index
    active_import = Current.user.user_imports.active.newest_first.first
    if active_import
      redirect_to admin_user_import_path(active_import)
    else
      @user_import = Current.user.user_imports.new
      @imports = Current.user.user_imports.newest_first.limit(10)
    end
  end

  def create
    @user_import = Current.user.user_imports.new(params.expect(user_import: [ :file ]))
    if @user_import.save
      redirect_to admin_user_import_path(@user_import), status: :see_other
    else
      @imports = Current.user.user_imports.newest_first.limit(10)
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @user_import = Current.user.user_imports.find(params[:id])
    @pagy, @results = pagy(:offset, @user_import.results.values.sort_by { |result| -result.fetch("position") }, limit: 25)
  end
end
