module Metrics
  class GroupMentions < MetricBase
    def analyze
      clear
      
      self.resource_group.resources.each do |res|
        # search feed for each keyword
        keywords.each do |partner, list|
          # save each keyword count
          mention_value = {}

          list.each do |keyword|
            count = Feed.where(resource_id: res.id).where.not(from_id: res.id).where("data LIKE '%#{keyword}%'").count

            mention_value[keyword] = count if count > 0
          end

          mention_value['__tagged__'] = FeedTag.joins(:feed).where(resource_id: partner, feeds: {resource_id: res.id}).count

          make_group_metric_model(name: 'mentions', owner: res, value: mention_value, resources: [Resource.find(partner)]) unless mention_value.blank?
        end
      end
    end

    def sort_value(value)
      mentions = 0
      value.each do |k,v|
        mentions += v
      end

      mentions
    end

  end
end