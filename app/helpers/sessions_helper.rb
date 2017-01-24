module SessionsHelper
  def sign_in(token)
    session[:auth_hash] = token
    session[:facebook] = Koala::Facebook::API.new(token['credentials']['token'])
    self.current_user = token
  end

  def signed_in?
    !current_user.nil? && current_user != ""
  end
  
  def current_user=(user)
    @current_user = user
  end
  
  def current_user
    @current_user ||= session[:auth_hash]
  end

  def assert_auth
    if !signed_in?
      redirect_to login_path
      return
    end
  end
end