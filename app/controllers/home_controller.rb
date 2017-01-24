class HomeController < ApplicationController
  #before_action :assert_auth

  def index
    index_groups
  end

  def index_groups
    @resource_groups = ResourceGroup.order(:group_name)
    @resource_group = ResourceGroup.new

    respond_to do |format|
      format.html { render template: "home/groups" }
      format.json { render json: @resources }
    end
  end
end
