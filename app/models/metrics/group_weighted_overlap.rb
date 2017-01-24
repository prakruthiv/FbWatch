module Metrics
  class GroupWeightedOverlap < MetricBase
    def analyze
      clear

      shared_metrics = GroupMetric.where(metric_class: 'shared_resources_metric', resource_group_id: self.resource_group.id)

      grouped_metrics = shared_metrics.group_by { |item| item.resources.to_a.map(&:id).push(item.resource_id).uniq.sort.join('_') }
      
      grouped_metrics.each do |key, metrics|
        post_result = []
        like_result = []
        tag_result = []
        mixed_result = []

        combination = nil

        metrics.each do |metric|
          case metric.name
            # since everything will be twice skip the second metric
            when 'shared_resources'
              post_result = metric.value if post_result.empty?
            when 'shared_resources_likes'
              like_result = metric.value if like_result.empty?
            when 'shared_resources_tagged'
              tag_result = metric.value if tag_result.empty?
            when 'shared_resources_any'
              mixed_result = metric.value if mixed_result.empty?
          end

          combination = metric.resources.to_a.dup.push(metric.resource) if combination.nil?
        end

        if mixed_result.empty?
          Rails.logger.warn "encountered malformed metrics group, key #{key}"
          next
        end

        # now look for frequency of interaction on both sides for weight
        posts_weighted = {}
        post_result.each do |res_id|
          comments = []
          posts = []

          combination.each do |target|
            # skip posts/comment on own posts
            next if target.id == res_id

            typed_frequency = Feed.where(resource_id: target).where("from_id = :id OR to_id = :id", id: res_id).group(:data_type).count(:id)
            comments << typed_frequency['comment'].to_i
            posts << typed_frequency['message'].to_i
          end

          # weigh posts twice as heavy as comments
          posts_weighted[res_id] = {
            comments: comments,
            posts: posts,
            score: (average_over_set(comments) * 1 + average_over_set(posts) * 2).round(2)
          }
        end

        all_likes = Like.includes(:feed).where(feeds: {resource_id: combination.map {|x| x.id}}, resource_id: like_result).
                                         group_by(&:resource_id)

        likes_weighted = calc_weighted_feed_addon(all_likes, {
          owner_post: 3,
          other_post: 1,
          owner_comment: 2,
          other_comment: 1
        })

        all_tags = FeedTag.includes(:feed).where(feeds: {resource_id: combination.map {|x| x.id}}, resource_id: tag_result).
                                           group_by(&:resource_id)

        tags_weighted = calc_weighted_feed_addon(all_tags, {
          owner_post: 2,
          other_post: 1,
          owner_comment: 2,
          other_comment: 1
        })

        # now combine all
        weighted_result = {}
        mixed_result.each do |res_id|
          posts_score = posts_weighted[res_id][:score] unless posts_weighted[res_id].nil?
          likes_score = likes_weighted[res_id][:score] unless likes_weighted[res_id].nil?
          tags_score = tags_weighted[res_id][:score] unless tags_weighted[res_id].nil?

          # weigh direct interaction twice as important
          modifier = combination.map(&:id).include?(res_id) ? 2 : 1

          weighted_result[res_id] = {
            posts: posts_weighted[res_id] || 0,
            likes: likes_weighted[res_id] || 0,
            tags: tags_weighted[res_id] || 0,
            total: (posts_score.to_f * 5 + likes_score.to_f * 3 + tags_score.to_f * 1).round(2) * modifier / 10
          }
        end

        make_mutual_group_metric_model(name: 'weighted_overlap', value: weighted_result, resources: combination)
      end
    end

    def sort_value(value)
      value.map { |k,v| v['total'] }.reduce(&:+).round(2)
    end

    def sorted_values(value)
      value.sort_by {|k,x| x['total'].to_f}.reverse
    end

    def empty?(value)
      value.empty?
    end

    private
      def average_over_set(set)
        Stats.geometric_mean(set.map { |x|
          [x, positive_value_indicator(set)].max
        }).round(2)
      end

      def positive_value_indicator(array)
        (array.max > 0) ? 1 : 0
      end

      def calc_weighted_feed_addon(collection, weights)
        story_weight = 0.5
        weighted = {}

        collection.each do |res_id, addons|
          addon_detail = {}

          addons.each do |addon|
            # skip likes/tags on own wall
            next if res_id == addon.feed.resource_id
            addon_detail[addon.feed.resource_id] ||= 0

            if addon.feed.data_type == 'story'
              addon_detail[addon.feed.resource_id] += story_weight
            elsif addon.feed.parent_id.nil?
              if addon.feed.from_id == addon.feed.resource_id
                addon_detail[addon.feed.resource_id] += weights[:owner_post]
              else
                addon_detail[addon.feed.resource_id] += weights[:other_post]
              end
            else
              if addon.feed.from_id == addon.feed.resource_id
                addon_detail[addon.feed.resource_id] += weights[:owner_comment]
              else
                addon_detail[addon.feed.resource_id] += weights[:other_comment]
              end
            end
          end

          weighted[res_id] = {
            data: addon_detail,
            score: average_over_set(addon_detail.map { |type, weight| weight })
          }
        end

        weighted
      end
  end
end