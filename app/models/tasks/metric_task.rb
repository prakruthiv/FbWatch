module Tasks
  class MetricTask < Base
    def self.type_name
      'metric'
    end

    def init_data
    end

    attr_accessor :resource_metrics, :group_metrics

    def resource_metrics
      @resource_metrics ||= Metrics::MetricBase.single_metrics
    end

    def group_metrics
      @group_metrics ||= Metrics::MetricBase.group_metrics
    end

    protected
      def task_run

        if @task.resource.is_a?(Resource)
          @total_parts = resource_metrics.length

          result = calc_metrics_for_resource(@task.resource)

        elsif @task.resource_group.is_a?(ResourceGroup)
          @total_parts = @task.resource_group.resources.length * resource_metrics.length + group_metrics.length

          result = []

          @task.resource_group.resources.each do |resource|
            result << calc_metrics_for_resource(resource)
          end

          result << run_group_metrics

        else
          raise 'Invalid options provided for MetricTask to run'
        end

        return result
      end

      def run_group_metrics
        run_metric_collection(metrics: group_metrics, resource_group: @task.resource_group)
      end

      def calc_metrics_for_resource(resource)
        run_metric_collection(metrics: resource_metrics, resource: resource)
      end

      def run_metric_collection(options)
        collection = options[:metrics] || []

        if options[:resource].nil? and options[:resource_group].nil?
          Rails.logger.warn "Missing entity in MetricTask with provided options: #{options}"
          return
        end

        collection.each do |metric_class|
          if metric_class.blank?
            Rails.logger.warn "empty metric_class value"
            next
          end
          Rails.logger.debug "running metric class #{metric_class}"
          
          metric_class = "Metrics::#{metric_class}"

          klass = metric_class.constantize.new(options)

          begin
            klass.analyze
          rescue => ex
            @task.error = true
            @task.save!
            Utility.log_exception(ex, mail: @send_mail, info: @task.inspect)
          end

          save_metric_models(klass.metrics) if klass.metrics.is_a?(Array)

          part_done
        end
      end

      def save_metric_models(collection)
        ActiveRecord::Base.transaction do 
          collection.each do |obj| 
            Utility.save_resource_gracefully(obj)
          end
        end

        collection.clear
      end

      def resume
        raise BreakingError.new(message: 'MetricTasks cannot be resumed at this moment')
      end
  end
end