module Metrics
  class ResourceStats < MetricBase
    @@id = "resource_stats"

    def analyze
      clear
      
      total_feed = Feed.where(resource_id: self.resource.id).count
      make_metric_model('total_feed_items', total_feed)

      posts_count = Feed.where({resource_id: self.resource.id, from_id: self.resource.id, data_type: "message"}).count
      make_metric_model('posts_by_owner', posts_count)

      posts_by_others_count = Feed.where({resource_id: self.resource.id, data_type: "message"}).where.not(from_id: self.resource.id).count
      make_metric_model('posts_by_others', posts_by_others_count)

      story_count = Feed.where({resource_id: self.resource.id, data_type: "story"}).count
      make_metric_model('story_count', story_count)

      resource_count = Feed.where(resource_id: self.resource.id).distinct.count(:from_id)
      make_metric_model('resources_on_feed', resource_count)

      resource_like_count = Like.joins(:feed).where(feeds: {resource_id: self.resource.id}).distinct.count(:resource_id)
      make_metric_model('resource_like_count', resource_like_count)

      resource_tag_count = FeedTag.joins(:feed).where(feeds: {resource_id: self.resource.id}).distinct.count(:resource_id)
      make_metric_model('resource_tag_count', resource_tag_count)

      total_likes = Like.joins(:feed).where(feeds: {resource_id: self.resource.id}).count
      make_metric_model('total_likes', total_likes)

      total_likes_given = Like.where(resource_id: self.resource.id).count
      make_metric_model('total_likes_given', total_likes_given)

      total_tags = FeedTag.joins(:feed).where(feeds: {resource_id: self.resource.id}).count
      make_metric_model('total_tags', total_tags)

      total_tagged = FeedTag.where(resource_id: self.resource.id).count
      make_metric_model('total_tagged', total_tagged)

      feed_type_stats('link')
      feed_type_stats('photo')
      feed_type_stats('status')
      feed_type_stats('comment')
      feed_type_stats('video')
      feed_type_stats('swf')
      feed_type_stats('checkin')
    end

    def feed_type_stats(type)
      total = Feed.where(resource_id: self.resource.id, feed_type: type).count
      make_metric_model("total_#{type}", total)

      total_own = Feed.where(resource_id: self.resource.id, feed_type: type, from_id: self.resource.id).count
      make_metric_model("total_own_#{type}", total_own)

      total_else = Feed.where(feed_type: type, from_id: self.resource.id).where.not(resource_id: self.resource.id).count
      make_metric_model("total_else_#{type}", total_else)
    end

    def view_name(name)
      @@id
    end

    def vars_for_render(options)
      {
        friendly_name: @@friendly_names[options[:name]]
      }
    end
    
    @@friendly_names = {
      'total_feed_items' => 'Total Feed Items',
      'posts_by_owner' => 'Posts made by Owner',
      'posts_by_others' => 'Posts made by Others',
      'story_count' => 'Stories',
      'resources_on_feed' => 'Resources Posted on Feed',
      'resource_like_count' => 'Resources Liked a Post',
      'total_likes' => 'Total Likes Received',
      'total_likes_given' => 'Total Likes Given',
      'total_tags' => 'Total Tags on Feed',
      'total_tagged' => 'Total Tagged',
      'total_link' => 'Total Links',
      'total_own_link' => 'Total Links by self',
      'total_else_link' => 'Total Links by self on other Feeds',
      'total_photo' => 'Total Photos',
      'total_own_photo' => 'Total Photos by self',
      'total_else_photo' => 'Total Photos by self on other Feeds',
      'total_status' => 'Total Statuses',
      'total_own_status' => 'Total Statuses by self',
      'total_else_status' => 'Total Statuses by self on other Feeds',
      'total_comment' => 'Total Comments',
      'total_own_comment' => 'Total Comments by self',
      'total_else_comment' => 'Total Comments by self on other Feeds',
      'total_video' => 'Total Videos',
      'total_own_video' => 'Total Videos by self',
      'total_else_video' => 'Total Videos by self on other Feeds',
      'total_swf' => 'Total SWFs',
      'total_own_swf' => 'Total SWFs by self',
      'total_else_swf' => 'Total SWFs by self on other Feeds',
      'total_checkin' => 'Total Checkins',
      'total_own_checkin' => 'Total Checkins by self',
      'total_else_checkin' => 'Total Checkins by self on other Feeds',
      'first_feed_activity' => 'First related activity',
      'first_feed_post' => 'First own post',
      'latest_feed_activity' => 'Last feed/message activity',
      'latest_feed_post' => 'Last post'
    }
  end
end