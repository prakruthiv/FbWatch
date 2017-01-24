module Metrics
  class NetworkGraphGoogle < MetricBase
    def analyze
      clear

      all_metrics = GroupMetric.where(resource_group_id: @resource_group.id, metric_class: 'google_mentions', name: 'google_mentions').
                                # group by source
                                order(:resource_id)

      all_scores = []

      all_metrics.each do |metric|
        all_scores << metric.sort_value if metric.sort_value >= 1
      end

      upper_boundary = all_scores.max + 1.0
      @clusters = [
        {
          max: upper_boundary - 1,
          min: upper_boundary / 10,
          score_max: 10,
          score_min: 5
        },
        {
          max: (upper_boundary - 1) / 10,
          min: upper_boundary / 100,
          score_max: 5,
          score_min: 2.5
        },
        {
          max: (upper_boundary - 1) / 100,
          min: upper_boundary / 1000,
          score_max: 2.5,
          score_min: 1
        }
      ]

      #crazy_mean = Stats.geometric_mean([Stats.geometric_mean(all_scores), all_scores.reduce(&:+) / all_scores.length])
      #geometric_mean = Stats.geometric_mean(all_scores.map { |x| (x < crazy_mean/1000 or x > crazy_mean*1000) ? nil : x }.compact)

      #deviation = confidence_deviation(all_scores, geometric_mean)
      #lower_boundary = [geometric_mean / 1000, all_scores.min].max
      #upper_boundary = [geometric_mean * 1000, all_scores.max].min

      graph_score = {
        edges: {},
        nodes: {}
      }

      all_metrics.group_by(&:resource_id).each do |res_id, group|
        graph_score[:nodes][res_id] ||= []

        group.each do |metric|
          next if metric.self_referencing?
          target_id = metric.resources.first.id

          normalized_score = cluster_value(metric.sort_value)
          #normalized_score = normalize_weight([metric.sort_value - lower_boundary, 0].max, geometric_mean - lower_boundary)
          #[[((metric.sort_value - lower_boundary) / (upper_boundary - lower_boundary)), 0].max, 1].min * 10

          graph_score[:nodes][target_id] ||= []
          graph_score[:nodes][target_id] << normalized_score
          graph_score[:nodes][res_id] << normalized_score

          graph_score[:edges][ [res_id, target_id].min ] ||= {}
          graph_score[:edges][ [res_id, target_id].min ][ [res_id, target_id].max ] ||= []
          graph_score[:edges][ [res_id, target_id].min ][ [res_id, target_id].max ] << normalized_score
        end
      end

      max_nodes_score = 0
      graph_score[:nodes].each do |res_id, node|
        graph_score[:nodes][res_id] = node.reduce(&:+) / node.length

        max_nodes_score = graph_score[:nodes][res_id] if graph_score[:nodes][res_id] > max_nodes_score
      end
      graph_score[:nodes].each do |res_id, node|
        make_group_metric_model(name: 'graph_node', value: (node / max_nodes_score * 10).round(2), owner: res_id, resources: [])
      end

      max_edge_score = 0
      graph_score[:edges].each do |source_id, edges|
        edges.each do |target_id, edge|
          graph_score[:edges][source_id][target_id] = edge.reduce(&:+) / edge.length

          max_edge_score = graph_score[:edges][source_id][target_id] if graph_score[:edges][source_id][target_id] > max_edge_score
        end
      end
      graph_score[:edges].each do |source_id, edges|
        edges.each do |target_id, edge|
          make_group_metric_model(name: 'graph_edge', value: (edge / max_edge_score * 10).round(2) , owner: Resource.find(source_id), resources: [Resource.find(target_id)])
        end
      end

    end

    def show_in_overview?
      true
    end

    def sort_value(value)
      value
    end

    private
      def cluster_value(value)
        @clusters.each do |cluster|
          if value >= cluster[:min] and value <= cluster[:max]
            return (value - cluster[:min]) / (cluster[:max] - cluster[:min]) * (cluster[:score_max] - cluster[:score_min]) + cluster[:score_min]
          end
        end

        0.1
      end

      def confidence_deviation(values, geometric_mean)
        # TODO this loop is pretty awful
        percentage_included = 0
        deviation = 1.1
        loop do
          percentage_included = values_in_interval(values, geometric_mean / deviation, geometric_mean * deviation) / values.length
          break if percentage_included >= 0.8
          deviation *= 1.1
        end

        deviation
      end

      def values_in_interval(values, from, to)
        count = 0
        values.each do |x|
          count += 1 if x >= from and x <= to
        end
        count
      end

      def normalize_weight(value, center)
        value + Math.sqrt(2* (center**2)) - Math.sqrt((value - center) ** 2 + (center ** 2))
      end
  end
end