class UsersController < ApplicationController
  before_action :correct_user,   only: [:kill, :edit, :update]

  def new
    @user = User.new
    @logins = User.all.map {|user| user.login}
    @emails = User.all.map {|user| user.email}
  end

  def create
    @user = User.new(user_params)
    @user.latitude, @user.longitude = cookies[:lat_lng].split("|")
    if @user.save
      log_in @user
      flash[:error_activation] = 'Account is not activated.' unless @user.activated
      UserMailer.account_activation(@user).deliver_now
      redirect_to @user
    else
      render 'new'
    end
  end

  def show
    @user = User.find(params[:id])
    @activity = find_activity @user
    @posts = @user.posts.paginate(page: params[:page], per_page: 5).order('id DESC')
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to @user
    else
      render 'edit'
    end
  end

  def kill
    @user = User.find(params[:id])
    if BCrypt::Password.new(@user.password_digest).is_password?(params[:user][:password])
      log_out
      @user.destroy
      redirect_to root_path
    else
      redirect_to @user
    end
  end

  private
    def user_params
      params.require(:user).permit(:login, :email, :password, :password_confirmation)
    end

    def find_activity user
      {:post => user.posts.all.count,
       :comment => user.comments.all.count}
    end

    def correct_user
      redirect_to login_path unless (current_user == User.find_by(id: params[:id]))
    end
end
