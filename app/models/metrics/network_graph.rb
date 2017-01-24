module Metrics
  class NetworkGraph < MetricBase
    def analyze
      clear

      all_metrics = GroupMetric.where(resource_group_id: @resource_group.id, metric_class: 'scoring', name: 'relationship_score').
                                # group by source
                                order(:resource_id).group_by(&:resource_id)

      graph_score = {
        edges: {},
        nodes: {}
      }

      all_metrics.each do |res_id, group|
        graph_score[:nodes][res_id] ||= []

        group.each do |metric|
          next if metric.self_referencing?
          target_id = metric.resources.first.id

          graph_score[:nodes][target_id] ||= []
          graph_score[:nodes][target_id] << metric.sort_value
          graph_score[:nodes][res_id] << metric.sort_value

          graph_score[:edges][ [res_id, target_id].min ] ||= {}
          graph_score[:edges][ [res_id, target_id].min ][ [res_id, target_id].max ] ||= []
          graph_score[:edges][ [res_id, target_id].min ][ [res_id, target_id].max ] << metric.sort_value
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
  end
end