module Tasks
  class Error < StandardError
    attr_accessor :cause, :task
    
    def initialize(options)
      message = options[:message]

      if options[:cause].is_a?(StandardError)
        message = options[:cause].message if message.nil?

        self.cause = options[:cause]
        self.set_backtrace(self.cause.backtrace)
      end

      self.task = options[:task]

      super(message)
    end
  end

  class RetriableError < Error; end
  class BreakingError < Error; end


  class Base
    attr_accessor :task, :send_mail

    def self.get_for(options)
      options[:running] ||= true
      options[:type] ||= type_name unless type_name.nil?

      Task.where(options)
    end

    def self.type_name
      nil
    end
    
    def initialize(options = {})
      if options[:task].is_a?(Task)
        use_existing_task(options[:task])
      else
        create_new_task(options)
      end

      @send_mail = options[:send_mail] || true
    end

    def use_existing_task(task)
      @task = task
      init_data
    end

    def create_new_task(options)
      resource = options[:resource] || nil
      resource_group = options[:resource_group] || nil

      if !options[:data].nil? and !options[:data].is_a?(Hash)
        Rails.logger.warn "Invalid :data value #{options[:data]}, expected Hash"
        options[:data] = {}
      end
      data = options[:data] || {}

      @task = Task.new
      @task.resource = resource
      @task.resource_group = resource_group
      @task.type = self.class.type_name
      @task.progress = 0.0
      @task.duration = 0
      @task.data = data
      @task.save!

      init_data
    end

    # overwrite me
    def init_data; end

    def run
      @start_duration = @task.duration
      @start = Time.now
      
      @task.running = true
      @task.save!

      begin
        if task_resumed
          result = resume
        else
          result = task_run
        end
      rescue => error
        result = BreakingError.new(cause: error, task: @task)
        @task.error = true
        @task.save!
        Utility.log_exception(error, mail: @send_mail, info: "Rescued from unexpected error in task #{@task.inspect}")
      end
      
      @task.running = false
      @task.duration = @start_duration + (Time.now - @start)
      @task.save!

      return result
    end

    protected
      def task_resumed
        @resumed ||= @task.progress != 0.0
      end

      def part_done
        @total_parts ||= 1 # that is for a single resource
        # doing it that way to come by a full 1.0 if we encounter disabled resources in a collection
        @parts_done ||= 0
        @parts_done += 1

        @start_progress ||= @task.progress

        # if resuming a query we want to gracefully start to count upwards where we left of. otherwise this is 1
        @progress_modifier ||= 1.0

        @task.progress = @parts_done * @progress_modifier / @total_parts
        
        if task_resumed
          @task.progress += @start_progress
        end

        # because of precision a task might appear to be done when it's not really
        if @task.progress == 1.0 and @parts_done < @total_parts
          @task.progress = 0.99
        end

        @task.duration = @start_duration + (Time.now - @start)
        @task.save!
      end
  end
end