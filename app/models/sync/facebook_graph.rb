module Sync
  class ConnectionError < StandardError; end

  class FacebookGraph

    def initialize(koala)
      @koala = koala
    end

    def logger
      @logger ||= Rails.logger
    end

    def logger=(logger)
      @logger = logger
    end

    def facebook
      @koala
    end

    def query(path)
      logger.debug "Facebook Graph: sending '#{path}'..."

      exception = nil

      begin
        result = @koala.api(path)
      rescue => e 
        exception = e
      end

      if result.nil?
        exception = ConnectionError.new("Empty result object")
      end

      if exception
        logger.error "Received Error: #{exception.message}"
        logger.info "-- result: #{exception.inspect}"

        exception
      else
        logger.debug "Received: " + result.to_s[0..100]

        result
      end
    end
  end
end