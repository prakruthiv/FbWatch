module Tasks
  class GoogleMetricTask < MetricTask
    RESUME_KEY = 'resume'

    def self.type_name
      'google_metric'
    end

    def init_data
      @task.data[RESUME_KEY] ||= []

      # misusing this for loading error classes
      Metrics::GoogleMentions
    end

    protected
      def task_run
        halt = false

        if @task.resource_group.is_a?(ResourceGroup)
          @total_parts = 2

          begin
            result = run_google_metric('GoogleMentions')
          rescue Metrics::GoogleCaptchaError => ex
            @task.data[RESUME_KEY] = ex.resume_pairs
            @task.save!
            halt = true

            result = Tasks::RetriableError.new(task: @task)
          end

          result = run_google_metric('NetworkGraphGoogle') unless halt
        else
          raise 'Invalid options provided for MetricTask to run'
        end

        @task.data[RESUME_KEY] = [] if halt == false

        return result
      end

      def resume
        task_run
      end

      def run_google_metric(metric_class)
        if metric_class.blank?
          Rails.logger.warn "empty metric_class value"
          return
        end
        Rails.logger.debug "running metric class #{metric_class}"
        
        metric_class = "Metrics::#{metric_class}"

        klass = metric_class.constantize.new(resource_group: @task.resource_group, resume: @task.data[RESUME_KEY])

        klass.analyze

        save_metric_models(klass.metrics) if klass.metrics.is_a?(Array)

        part_done
      end
  end
end