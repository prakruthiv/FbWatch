class Resource < ActiveRecord::Base
  validates :username, :presence => true
  validates :facebook_id, :uniqueness => true
  
  has_many :basicdata
  # wrong naming scheme for feed (singular)
  has_many :feed
  
  has_many :metrics
  has_many :group_metrics

  has_and_belongs_to_many :resource_groups
  
  def to_fb_hash
    { 
      id: self.facebook_id, 
      name: self.name
     }
  end

  def activate
    self.active = true
  end

  def deactivate
    self.active = false
  end

  def sync_complete?
    last_q = Basicdata.where({resource_id: self.id, key: Tasks::SyncTask::FEED_KEY_LAST}).first

    !resume_query.nil? and last_q.is_a?(Basicdata) and last_q.value.blank?
  end

  def resume_query
    last_q = Basicdata.where({resource_id: self.id, key: Tasks::SyncTask::FEED_KEY_LAST}).first

    return last_q if last_q.is_a?(Basicdata) and !last_q.value.blank?

    newest_post = Feed.select(:created_time).where(resource_id: self.id, parent_id: nil).order("created_time DESC").limit(1).first
    return nil if newest_post.nil?

    "/#{self.facebook_id}/feed?since=#{newest_post.created_time.strftime("%s")}"
  end

  def resume_query=(query)
    entry = Basicdata.where({resource_id: self.id, key: Tasks::SyncTask::FEED_KEY_LAST}).first_or_initialize
    entry.value = query
    entry.save
  end

  def dummy?
    self.feed.count == 0
  end

  def color
    color = Basicdata.where(resource_id: self.id, key: 'node_color').first
    return color.value unless color.nil?
  end

  def currently_syncing?
    self.last_synced.is_a?(Time) and self.last_synced > DateTime.now
  end

  def clear
    self.last_synced = nil
    # resource.active = false
    ActiveRecord::Base.transaction do 
      Like.joins(:feed).where(feeds: {resource_id: self.id}).readonly(false).destroy_all
      FeedTag.joins(:feed).where(feeds: {resource_id: self.id}).readonly(false).destroy_all

      self.feed.destroy_all
      self.basicdata.destroy_all
      self.metrics.destroy_all
      self.group_metrics.destroy_all
      self.save
    end
  end

  def tasks
    Tasks::Base.get_for(resource: self)
  end

  def build_detail_json

    flash[:alert] << "Start of function - build_detail_json"


    load_start = Time.now
    feeds = Feed.includes(:to, :from, likes: [:resource], feed_tags: [:resource]).order("parent_id ASC, updated_time DESC").where(resource_id: self.id).load
    likes = Like.includes(:resource).joins(:feed).where(feeds: {resource_id: self.id})
    tags = FeedTag.includes(:resource).joins(:feed).where(feeds: {resource_id: self.id})
    load_end = Time.now

    build_start = Time.now
    # build basic structure
    json = {
      id: self.facebook_id,
      name: self.name,
      username: self.username,
      link: self.link
    }

    # AM
    flash[:alert] << "Start of function  #{json}"

    bdata_start = Time.now
    # add all special values from the basicdata store
    self.basicdata.each do |basic_hash|
      json[ basic_hash.key ] = basic_hash.value
    end
    json.delete('feed_previous_link')
    json.delete('feed_last_link')
    bdata_end = Time.now

    likes_start = Time.now
    # go through all likes to setup
    all_likes = {}
    likes.each do |like|
      all_likes[like.feed_id] ||= []
      all_likes[like.feed_id] << like
    end
    likes_end = Time.now

    tags_start = Time.now
    all_tags = {}
    tags.each do |tag|
      all_tags[tag.feed_id] ||= []
      all_tags[tag.feed_id] << tag
    end
    tags_end = Time.now

    # pre-select all comments
    comments = {}

    feed_start = Time.now
    # add feed items
    feed_struct = []
    feeds.each do |feed_item|
      # feed items with a parent are comments and injected in the corresponding item
      if !feed_item.parent_id.nil?
        comments[feed_item.parent_id] ||= []
        comments[feed_item.parent_id] << feed_item
        next
      end

      feed_hash = feed_item.to_fb_hash(comments: comments, likes: all_likes, tags: all_tags)
      
      feed_struct.push(feed_hash)
    end
    feed_end = Time.now
    
    json["feed"] = feed_struct

    build_end = Time.now

    Rails.logger.info "Load time: #{load_end-load_start}, Basicdata time: #{bdata_end-bdata_start}, likes time: #{likes_end-likes_start}, tags time: #{tags_end-tags_start}, feed time: #{feed_end-feed_start}, build time: #{build_end-build_start}"
    # AM
    flash[:alert] << "Processed data #{json}"

    return json

  end
end
