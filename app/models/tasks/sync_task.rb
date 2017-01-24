module Tasks
  class SyncTask < Base
    attr_accessor :gatherer, :koala
    
    ALL = 'all'

    FEED_KEY_PREV = 'feed_previous_link'
    FEED_KEY_LAST = 'feed_last_link'

    DATA_KEY_RESUME = 'unfinished_resources'
    DATA_KEY_FAILING = 'failing_resource'
    DATA_KEY_FAILURES = 'failures'
    DATA_TIME = 'data_time'
    SAVE_TIME = 'save_time'
    TIME_SPLIT = 'time_split'

    ERROR_ALREADY_SYNCING = 'ERROR_ALREADY_SYNCING'

    def self.type_name
      'sync'
    end

    def initialize(koala_or_options, options = {})
      @koala = koala_or_options if koala_or_options.is_a?(Koala::Facebook::API)

      options = koala_or_options if koala_or_options.is_a?(Hash)

      super(options)
    end

    def init_data
      @task.data[DATA_TIME] ||= 0
      @task.data[SAVE_TIME] ||= 0
      @task.data[TIME_SPLIT] ||= []
    end

    protected
      def task_run
        start = Time.now

        if @task.resource.is_a?(Resource)
          result = sync_resource(@task.resource, @task.data)

        elsif @task.resource_group.is_a?(ResourceGroup)
          @total_parts = @task.resource_group.resources.length
          result = sync_resource_collection(@task.resource_group.resources)

        elsif @task.resource_group == ALL
          resources = Resource.where(active: true)
          @total_parts = resources.length
          result = sync_resource_collection(resources)

        else
          raise 'Invalid options provided for SyncTask to run'
        end
        
        @task.data[TIME_SPLIT].push('%.2f' % (Time.now - start))
        @task.save!

        return result
      end

      def resume
        start = Time.now

        if @task.resource.is_a?(Resource)
          # syncing of a single resource failed. just do it again
          sync_resource(@task.resource, @task.data)
        else
          # syncing of a collection failed. look into the saved data to resume
          resources = Resource.where(id: @task.data[DATA_KEY_RESUME])
          @total_parts = resources.length
          @progress_modifier = 1.0 - @task.progress

          # remove resume data
          @task.data[DATA_KEY_RESUME] = nil

          result = sync_resource_collection(resources)
        end


        @task.data[TIME_SPLIT].push('%.2f' % (Time.now - start))
        @task.save!
      end

      def sync_resource_collection(collection)

        result = nil
        collection.each do |resource|
          if resource.active == false
            @total_parts -= 1
            next
          end

          if result.is_a?(StandardError)
            # a previous sync encountered a connection error, remember that the current resource was not yet synced
            @task.data[DATA_KEY_RESUME] << resource.id
          else
            result = sync_resource(resource)

            if result.is_a?(StandardError)
              @task.data[DATA_KEY_FAILING] = resource.id
              @task.data[DATA_KEY_RESUME] = [resource.id]
            end
          end
        end

        return result
      end

      def sync_resource(resource, options = {})
        if resource_currently_syncing?(resource)
          resource_failed_to_sync(resource, ERROR_ALREADY_SYNCING)
          return ERROR_ALREADY_SYNCING
        end

        setup_gatherer(resource)

        result = nil
        data_time = time do
          result = use_gatherer_to_sync(options)
        end

        save_time = time do
          begin
            Sync::UserDataSaver.new.save_resource(resource, result)
          rescue => exception
            resource.last_synced = DateTime.now
            resource.save

            raise exception, exception.message, exception.backtrace
          end
        end
        if result.is_a?(Hash)
          part_done
        else
          resource_failed_to_sync(resource, result)
        end

        @task.data[DATA_TIME] += data_time
        @task.data[SAVE_TIME] += save_time
        @task.save!

        resource.last_synced = DateTime.now
        resource.save

        return result
      end

      def resource_failed_to_sync(resource, result)
        @task.data[DATA_KEY_FAILURES] ||= {}
        @task.data[DATA_KEY_FAILURES][resource.id] = result.to_s
      end

      def use_gatherer_to_sync(options)
        tries = 0
        begin
          result = call_gatherer_safe(options)
          tries += 1
          # sometimes a very nasty error is encountered where "getaddrinfo cannot be found"
          # most of the times this is resolved the next time a connection is done
        end while result[:error].is_a?(Faraday::Error::ConnectionFailed) and tries < 10

        if result[:error].is_a?(Koala::Facebook::APIError) or result[:error].is_a?(Faraday::Error::ConnectionFailed)
          # if we reach this point the exception was thrown at the first call to get the basic information for a resource
          # i.e. not during the loop of getting the feed, this is important because if an error occurs during said loop
          # we want to be able to resume getting data at the point where it occured and not have to reload everything
          # this usually occurs if the request limit is reached (#17) or for any other permanent error
          Utility.log_exception(result[:error], mail: @send_mail, info: @task.inspect)
          return RetriableError.new(cause: result[:error], task: @task)
        elsif result[:error].is_a?(StandardError)
          Utility.log_exception(result[:error], mail: @send_mail, info: @task.inspect)
          return BreakingError.new(cause: result[:error], task: @task)
        end

        return result
      end

      def call_gatherer_safe(options)
        @gatherer.page_limit = options["page_limit"] unless options["page_limit"].blank?

        begin
          result = @gatherer.fetch((options["pages"] || -1).to_i)
        rescue => e
          result = {:error => e}
        end

        result
      end

      def setup_gatherer(resource)
        @gatherer = Sync::UserDataGatherer.new(resource, @koala)
      end

      def resource_currently_syncing?(resource)
        return true if resource.currently_syncing?
      
        resource.last_synced = Time.now.tomorrow
        resource.save!
        return false
      end

      def time
        start = Time.now
        yield
        ('%.2f' % (Time.now - start)).to_f
      end
  end
end