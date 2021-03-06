class SessionsController < ApplicationController

  def new
    # debugger
  end

  def create
    @user = User.find_by(email: params[:session][:email].downcase)
    if @user && @user.authenticate(params[:session][:password])
      log_in @user
      # sessions_helperのrememberメソッドを呼び出している
      params[:session][:remember_me] == '1' ? remember(@user) : forget(@user) 
      # フレンドリーフォワーディングで記憶しておいたURLへリダイレクトする（ユーザーページ）
      redirect_back_or @user
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end