module Metrics
  class SharedResourcesMetric < MetricBase
    def analyze
      clear

      resource_combinations(2).each do |combination|

        # users posting on or posted on by owner for both resources
        post_result = Resource.find_by_sql [post_intersection_sql, combination[0].id, combination[1].id]
        make_mutual_group_metric_model(name: 'shared_resources', value: post_result.map { |x| x.id }, resources: combination)

        # users having liked a post/comment on both feeds
        like_result = Resource.find_by_sql [like_intersection_sql, combination[0].id, combination[1].id]
        make_mutual_group_metric_model(name: 'shared_resources_likes', value: like_result.map { |x| x.id }, resources: combination)

        # users having liked a post/comment on both feeds
        tag_result = Resource.find_by_sql [tag_intersection_sql, combination[0].id, combination[1].id]
        make_mutual_group_metric_model(name: 'shared_resources_tagged', value: tag_result.map { |x| x.id }, resources: combination)

        # intersection of users having either liked on or posted on (or being posted on) both feeds
        mixed_result = Resource.find_by_sql [any_intersection_sql, combination[0].id, combination[0].id, combination[0].id, combination[1].id, combination[1].id, combination[1].id]
        make_mutual_group_metric_model(name: 'shared_resources_any', value: mixed_result.map { |x| x.id }, resources: combination)
      end
    end

    def vars_for_render(options)
      if @vars_for_render.nil?
        # return a hash
        @vars_for_render = {
          friendly_name: @@friendly_names[options[:name]]
        }
      end
      @vars_for_render
    end

    def sort_value(value)
      return 0 if value.first.is_a?(Hash)
      res_array = value || []
      res_array.size 
    end

    def empty?(value)
      value.empty?
    end

    def metrics_by_token
      if @metrics_by_token.blank?
        @metrics_by_token ||= @metrics.group_by { |item| item.resources.map(&:id).sort.join('_') }

        @metrics_by_token.each do |token, group|
          aggregate = 0
          group.each { |item| aggregate += item.sort_value }

          @metrics_by_token[token] = {
            involved: group[0].resources.dup,
            aggregate: aggregate,
            details: group
          }
        end

        @metrics_by_token = @metrics_by_token.values.sort do |a, b|
          b[:aggregate] <=> a[:aggregate]
        end
      end

      @metrics_by_token
    end

    @@friendly_names = {
      'shared_resources' => 'posted',
      'shared_resources_likes' => 'liked',
      'shared_resources_tagged' => 'tagged',
      'shared_resources_any' => 'any'
    }

    private
      def post_intersection_sql

        # NOTE: The following query and comment was first used, but later exchanged because it was faster locally, but slower online
        # DO NOT add .count to the query like that. It would be really slow!
        # If a direct count is necessary remove the .distinct method and move to .select('DISTINCT resources.id').count
        # Only other acceptable version is #.count(:id, distinct: true), which is now deprecated though
        # result = Resource.distinct.select(resources: :id).joins('INNER JOIN feeds feed1 ON feed1.from_id = resources.id OR feed1.to_id = resources.id',
        #  'INNER JOIN feeds feed2 ON feed2.from_id = resources.id OR feed2.to_id = resources.id').
        #  where(feed1: {resource_id: }, feed2: {resource_id: 257})

        "SELECT A.id FROM (
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        A INNER JOIN (
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?) 
        B ON A.id = B.id"
      end

      def like_intersection_sql
        "SELECT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?) A
        INNER JOIN
        (SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?) B
        ON A.id = B.id"
      end

      def tag_intersection_sql
        "SELECT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?) A
        INNER JOIN
        (SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?) B
        ON A.id = B.id"
      end

      def any_intersection_sql
        "SELECT DISTINCT A.id FROM (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id 
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?
        ) A
        INNER JOIN
        (
          SELECT DISTINCT resources.id FROM resources INNER JOIN likes ON likes.resource_id = resources.id INNER JOIN feeds ON feeds.id = likes.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id FROM resources INNER JOIN feed_tags ON feed_tags.resource_id = resources.id INNER JOIN feeds ON feeds.id = feed_tags.feed_id
          WHERE feeds.resource_id = ?
          UNION
          SELECT DISTINCT resources.id
          FROM resources 
            INNER JOIN feeds 
              ON feeds.from_id = resources.id 
                OR feeds.to_id = resources.id 
          WHERE feeds.resource_id = ?
        ) B
        ON A.id = B.id"
      end
  end
end