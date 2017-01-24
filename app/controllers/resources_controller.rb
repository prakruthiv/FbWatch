require 'uri'
require 'json'

class ResourcesController < ApplicationController
  before_action :assert_auth, except: [:details, :overview]
  before_action :set_resource_by_id, only: [:add_to_group, :update, :destroy, :clear_last_synced, :change_keywords, :change_color]
  before_action :set_resource_by_username, only: [:details, :disable, :enable, :update, :show_clean_up, :do_clean_up, :overview]

  # GET /resources
  # GET /resources.json
  def index
    @offset = params[:p].to_i || 0

    @resources = Resource.order('active DESC, last_synced IS NULL, last_synced DESC, created_at ASC').page(@offset+1).per(100)
    @resource = Resource.new
    @total_res = Resource.count

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end

  def overview
    if @resource.nil?
      flash[:alert] << "Resource #{params[:username]} not found"
      return redirect_to :back
    end
  end
  
  # GET /resources/1
  # GET /resources/1.json
  def details
    if @resource.nil?
      flash[:alert] << "Resource #{params[:username]} not found"
      return redirect_to :back
    end

    # AM
    #flash[:alert] << "Is it Json data - #{params[:format]}"

    if params[:format] != 'json'
      puts params[:format]
      #format.html
       populate_view_variables_for_details
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @resource.build_detail_json }
     # AM
     # flash[:alert] << "Return data #{format.json}"
    end
  end

  # POST /resources
  # POST /resources.json
  def create
    if params[:resource].has_key?(:username)
      username = parse_facebook_url(params[:resource][:username])
      success = create_for(username)
    elsif params[:resource].has_key?(:usernames)
      success = true
      usernames = params[:resource][:usernames].split(/\r?\n/)
      usernames.each do |username|
        create_for(parse_facebook_url(username))
      end
    else
      # TODO error handling
    end
    
    respond_to do |format|
      if success
        flash[:notice] << 'Resource was successfully created.'
        format.html { redirect_to :back }
        format.json { render json: @resource, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def search_for_name
    @resources = Resource.select([:id, :username, :name]).
                          where("name like :q OR username like :q", q: "%#{params[:q]}%").
                          order('name, username').page(params[:page]).per(params[:per])

    resources_count = Resource.select([:id, :username, :name]).
                          where("name like :q OR username like :q", q: "%#{params[:q]}%").count

    respond_to do |format|
      format.json { render json: {total: resources_count, resources: @resources.map { |e| {id: e.id, text: "#{e.name} (#{e.username})"} }} }
    end
  end

  def show_change_color_batch  
  end

  ##############
  # edit methods
  ##############

  def clear_last_synced
    @resource.last_synced = nil
    @resource.save!

    redirect_to resource_details_path(@resource.username)
  end

  def show_clean_up
    # note apparently the exact same post/comment can appear multiple times on a users feed
    # this will remove those duplicates cause for our use case the content is more important
    duplicate_feeds = Feed.select(:facebook_id, :created_time, :from_id, :to_id, :resource_id).
         group(:facebook_id, :created_time, :from_id, :to_id, :resource_id).
         having('count(facebook_id) > 1 AND resource_id = ?', @resource.id)

    @feeds = []
    duplicate_feeds.each do |dupe|
      @feeds.concat(Feed.where(facebook_id: dupe.facebook_id, created_time: dupe.created_time, from_id: dupe.from_id, to_id: dupe.to_id, resource_id: dupe.resource_id).to_a)
    end
  end

  def do_clean_up
    duplicate_feeds = Feed.select(:facebook_id, :created_time, :from_id, :to_id, :resource_id).
         group(:facebook_id, :created_time, :from_id, :to_id, :resource_id).
         having('count(facebook_id) > 1 AND resource_id = ?', @resource.id)

    duplicate_feeds.each do |dupe|
      dupes = Feed.where(facebook_id: dupe.facebook_id, created_time: dupe.created_time, from_id: dupe.from_id, to_id: dupe.to_id, resource_id: dupe.resource_id)

      dupes.shift

      dupes.each do |res|
        res.destroy
      end
    end

    flash[:notice] << "Duplicates have been removed"

    redirect_to resource_details_path(@resource.username)
  end

  def add_to_group
    @resource.resource_groups << ResourceGroup.find(params[:resource][:resource_groups])
    @resource.save

    redirect_to resource_details_path(@resource.username)
  end
  
  def change_keywords
    keywords = Basicdata.where(resource_id: @resource.id, key: 'keywords').first_or_initialize
    keywords.value = params[:basicdata][:value]
    keywords.save!

    flash[:notice] << "Keyword updated"
    redirect_to :back
  end
  
  def change_color
    color = Basicdata.where(resource_id: @resource.id, key: 'node_color').first_or_initialize
    color.value = params[:basicdata][:value]
    color.save!

    flash[:notice] << "Color updated"
    redirect_to :back
  end

  def change_color_batch
    require 'json'

    color_hash = JSON.parse(params[:array])

    color_hash.each do |res_color|
      res = Resource.where(facebook_id: res_color["facebook_id"]).first
      if res.nil?
        flash[:warning] << "Facebook user with id #{res_color['facebook_id']} not found"
        next
      end

      color = Basicdata.where(resource_id: res.id, key: 'node_color').first_or_initialize
      color.value = res_color['color']
      color.save
    end

    flash[:notice] << "Colors updated"
    redirect_to root_path
  end
  
  def disable
    @resource.deactivate
    @resource.save
    
    flash[:notice] << "Disabled #{@resource.username}"
    redirect_to :back
  end
  
  def enable
    @resource.activate
    @resource.save

    flash[:notice] << "Enabled #{@resource.username}"
    redirect_to :back
  end

  # PUT /resources/1
  # PUT /resources/1.json
  def update
    respond_to do |format|
      if @resource.update_attributes(resource_params)
        flash[:notice] << 'Resource was successfully updated.'
        format.html { redirect_to @resource }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.json
  def destroy
    @resource.clear
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end

  private
    def populate_view_variables_for_details

      # AM
      #flash[:alert] << "Start of function - populate_view_variables_for_details"


      @offset = params[:p].to_i || 0
      
      filter_hash = {resource_id: @resource.id}
      @filter = params[:f]
      if !@filter.nil? and !@filter.empty?
        filter_hash[:data_type] = @filter
      else
        filter_hash[:parent_id] = nil
      end

      #@feeds = Feed.includes(:to, :from).order("created_time DESC").where(filter_hash).page(@offset+1).per(100)
      @feeds = Feed.includes(:to, :from).order("created_time DESC").where(filter_hash).page(@offset+1).per(100)

      @graph = Koala::Facebook::API.new("EAAZApjxZAZAbZA0BAHiZCM92UZBie8iu9bzV0wQV1TOTgK0BzXVL2jD4CmdkCtMx70ZBeNSduZC2g5ul0TamdKgA1ZAxZBdrm8MPtZAosQdaZAkwq6FKsNpZAWEMOcEThsvPQJUYtaeguUmZB7Jx0UCU4bJhZBblTZCyR8BqJkx3bzpUMz5KdgZDZD")
      @feed_from_fb = @graph.get_connections("#{@resource.username}", "feed")
 
	 #AM
     #flash[:alert] << "Feed  messages - #{@feeds} "


      @filter_count = Feed.where(filter_hash).count
      @total_pages = (@filter_count / 100.0).ceil

      @metrics = Metric.where(resource_id: @resource.id).order(:metric_class).group_by(&:metric_class)

      @group_metrics = @resource.group_metrics.group_by(&:metric_class)
      @group_metrics.each do |metric_class, group|
        @group_metrics[metric_class] = group.sort_by(&:sort_value).reverse
      end
      
      @all_groups = ResourceGroup.all

      flash[:info] << "Note one or more tasks are currently running on this resource!" if @resource.tasks.count > 0
      flash[:info] << "This resource is currently syncing" if @resource.currently_syncing?

      @keywords = Basicdata.where(key: 'keywords', resource_id: @resource.id).first_or_initialize

      @color = Basicdata.where(key: 'node_color', resource_id: @resource.id).first_or_initialize

    end

    def create_for(username)
      if username.nil?
        flash[:notice] << 'Invalid URI provided'
        return false
      end

      begin
        basicdata = session[:facebook].get_object(username)
      rescue Koala::Facebook::ClientError => e
        flash[:alert] << "failed to create resource for #{username}. facebook returned an error: #{e.fb_error_message}"
        return false
      end
      
      @resource = Resource.find_by_facebook_id(basicdata['id'])
      if @resource.nil?
        @resource = Resource.new
        @resource.facebook_id = basicdata['id']
      end
      
      @resource.username = basicdata['username'] || basicdata['id']
      @resource.name = basicdata['name']
      @resource.link = basicdata['link']
      @resource.active = true

      success = false
      begin
        success = @resource.save
        if params[:resource][:resource_groups]
          group = ResourceGroup.find(params[:resource][:resource_groups])
          @resource.resource_groups << group unless group.nil?
        end
      rescue => e
        if e.is_a? ActiveRecord::RecordNotUnique
          alert = 'This resource seems to be already in the database!'
        else
          alert = 'Some error occured: ' + e.message
        end
        flash[:alert] << alert
      end

      return success
    end

    def parse_facebook_url(url)
      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError => e
        logger.debug("Invalid URI provided: #{url}")
        return nil
      end
      
      # the path of the facebook url holds either the unique name or the facebook id
      path = uri.path.split('/')

      # if it's a page or group the id is in the last "folder"
      # otherwise this will just return the unique name
      return path[-1]
    end

    def set_resource_by_id
      @resource = Resource.find(params[:id])
    end

    def set_resource_by_username
      @resource = Resource.where(username: params[:username]).first
    end

    def resource_params
      params[:resource].permit(:active, :facebook_id, :last_synced, :name, :username, :link)
    end
end
