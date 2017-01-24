class ApitestController < ApplicationController
  before_action :assert_auth
  
  def index
    fetcher = Sync::FacebookGraph.new(session[:facebook])
    if params.has_key?(:query)
      @query = params[:query]

      @result = fetcher.query(@query)
    end
    
    @user = fetcher.query('/me')
    @token = session[:facebook].access_token
    flash[:alert] << "Token - #{@token}"
  end
end
