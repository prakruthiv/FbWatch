module Metrics
  class MetricBase
    @@resource_metrics = ['ResourceStats', 'SingleUsersMetric', 'FeedTimeline']
    @@group_metrics = ['SharedResourcesMetric', 
      'GroupWeightedOverlap',
      'GroupMentions', 
      'Scoring', 'NetworkGraph'
    ]
    @@visualization_metrics = ['NetworkGraph', 'NetworkGraphGoogle']

    def self.single_metrics(ids = nil)
      if ids.nil?
        @@resource_metrics
      else
        @@resource_metrics.values_at(*ids)
      end
    end

    def self.group_metrics(ids = nil)
      if ids.nil?
        @@group_metrics
      else
        @@group_metrics.values_at(*ids)
      end
    end

    def self.visualization_metrics
      @@visualization_metrics
    end

    attr_accessor :metrics, :resource, :resource_group

    def initialize(options = {})
      set_options(options)

      @metrics = []
    end

    def resource_combinations(size)
      if !self.resource_group.nil? and self.resource_group.resources.length > 1
        return self.resource_group.resources.to_a.combination(size).to_a
      end
      
      []
    end

    def clear
      ActiveRecord::Base.transaction do
        Metric.where(metric_class: self.class_name, resource_id: @resource.id).destroy_all if @resource.is_a?(Resource)
        GroupMetric.where(metric_class: self.class_name, resource_group_id: @resource_group.id).destroy_all if @resource_group.is_a?(ResourceGroup)
      end
    end

    def set_options(options)
      @resource = options[:resource]
      @resource_group = options[:resource_group]
    end

    def class_name
      self.class.name.demodulize.underscore
    end

    def make_metric_model(name, value)
      metric = Metric.where({ metric_class: self.class_name, name: name, resource_id: @resource.id }).first_or_initialize

      metric.value = value
      
      @metrics.push(metric)
    end

    def show_in_overview?
      false
    end

    def make_group_metric_model(options)
      owner = options[:owner]
      owner = owner.id if owner.is_a?(Resource)

      # TODO sanity checks maybe?
      metric = GroupMetric.new( 
        metric_class: self.class_name, 
        name: options[:name], 
        resource_group_id: @resource_group.id,
        resource_id: owner)

      metric.value = options[:value]

      options[:resources].each do |res|
        metric.resources << res unless metric.resources.include?(res)
      end
      metric.resources.each do |res|
        metric.resources.delete(res) unless options[:resources].include?(res)
      end

      @metrics.push(metric)
      #if !metric.save
      #  Rails.logger.error "Couldn't save metric #{options[:name]} (errors: #{metric.errors.full_messages}"
      #end
    end

    def make_mutual_group_metric_model(options)
      options[:resources].each do |resource|

        involved = options[:resources].to_a.dup
        involved.delete(resource)

        make_group_metric_model({
          owner: resource.id,
          resources: involved,
          value: options[:value],
          name: options[:name]
        })
      end
    end

    def set(collection)
      @metrics = collection
      self
    end

    def keywords
      if @keywords.nil?
        @keywords = {}
        self.resource_group.resources.each do |res|
          custom_keywords = Basicdata.where(resource_id: res.id, key: 'keywords').pluck(:value).first

          @keywords[res.id] = [
            res.name,
            res.username,
            res.facebook_id
          ]

          unless custom_keywords.nil?
            custom_keywords.split(',').each do |key|
              @keywords[res.id] << key.strip
            end
          end
        end
      end

      @keywords
    end

    def resource_metric?
      @resource.nil? == false
    end

    def group_metric?
      @resource_group.nil? == false
    end
  end
end