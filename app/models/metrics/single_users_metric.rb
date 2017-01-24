module Metrics
  class SingleUsersMetric < MetricBase
    @@id = "single_users_metric"

    def analyze
      clear
      
      fans = Resource.joins('INNER JOIN feeds ON feeds.from_id = resources.id').where(feeds: {resource_id: self.resource.id}).
                      where.not(id: self.resource.id).limit(10).group('resources.id').order('COUNT(resources.id) DESC').count(:id)
      make_metric_model('fans', fans)

      fans_self = Resource.joins('INNER JOIN feeds ON feeds.resource_id = resources.id').where(feeds: {from_id: self.resource.id}).
                           where.not(feeds: {resource_id: self.resource.id}).limit(10).group('resources.id').order('COUNT(resources.id) DESC').count(:id)
      make_metric_model('fans_self', fans_self)

      fans_like = Like.joins(:feed).where(feeds: {resource_id: self.resource.id}).limit(10).group('likes.resource_id').order('COUNT(likes.id) DESC').count(:id)
      make_metric_model('fans_like', fans_like)

      feeds_i_like = Feed.joins(:likes).where(likes: {resource_id: self.resource.id}).
                          where.not(resource_id: self.resource.id).limit(10).group('feeds.resource_id').order('COUNT(feeds.id) DESC').count(:id)
      make_metric_model('feeds_i_like', feeds_i_like)

      fans_tag = FeedTag.joins(:feed).where(feeds: {resource_id: self.resource.id}).limit(10).
                         group('feed_tags.resource_id').order('COUNT(feed_tags.id) DESC').count(:id)
      make_metric_model('fans_tag', fans_tag)

      feeds_i_tag = Feed.joins(:feed_tags).where(feed_tags: {resource_id: self.resource.id}).
                         where.not(resource_id: self.resource.id).limit(10).group('feeds.resource_id').order('COUNT(feeds.id) DESC').count(:id)
      make_metric_model('feeds_i_tag', feeds_i_tag)
    end

    def vars_for_render(options)
      users_data = []
      options[:value].each do |uid, amount|
        users_data << {
          resource: Resource.find(uid),
          amount: amount
        }
      end

      users_data = users_data.sort do |a,b|
        b[:amount] <=> a[:amount]
      end

      {
        friendly_name: @@friendly_names[options[:name]],
        data: users_data
      }
    end

    def view_name(name)
      @@id
    end

    @@friendly_names = {
      'fans' => 'Biggest Fans by Posts',
      'fans_self' => 'Feeds user is on',
      'fans_like' => 'Likers on feed',
      'feeds_i_like' => 'Feeds I liked',
      'fans_tag' => 'Tags on feed',
      'feeds_i_tag' => 'Feeds I am tagged'
    }
  end
end