require "net/http"
require "uri"
require 'sanitize'
require 'watir-webdriver'
require 'open-uri'

module Metrics
  class GoogleCaptchaError < StandardError
    def initialize(message = "", resume_pairs = nil)
      super(message)

      @resume_pairs = resume_pairs
    end

    def resume_pairs
      @resume_pairs
    end
  end

  class GoogleMentions < MetricBase
    def initialize(options)
      super(options)

      @is_resuming = false
      if options[:resume]
        @combinations = options[:resume].map do |array|
          [
            Resource.find(array.first),
            Resource.find(array.second)
          ]
        end
        @is_resuming = true
      end

    end

    def analyze
      clear unless @is_resuming
      @logger = Logger.new("#{Rails.root}/log/google_mentions.log")

      resume_pairs = []
      halt = false

      combinations.each do |combination|
        if halt
          resume_pairs << combination.map(&:id)
        else
          # calc shared resources
          begin
            web_results = query_google_keywords(keywords_for(combination))
          rescue GoogleCaptchaError => e
            @logger.warn "-- google detected bot activity, pausing task"
            halt = true
            resume_pairs << combination.map(&:id)
          end
        end

        unless halt
          make_mutual_group_metric_model(name: 'google_mentions', value: web_results, resources: combination)
          @logger.debug "-- count #{web_results[:count]}"

          # wait for some time to avoid detection, not really helping
          # sleep Random.rand(0..30)
        end
      end
      
      clear_browser

      if halt
        raise GoogleCaptchaError.new("", resume_pairs)
      end
    end

    def combinations
      if @combinations.blank?
        @combinations = resource_combinations(2)
      end

      @combinations
    end

    def clear_browser
      unless @watir_browser.nil?
        @watir_browser.close
        @headless.destroy if @headless

        @watir_browser = nil
        @headless = nil
      end
    end

    def keywords_for(resources)
      return [] unless resources.is_a?(Array)

      keywords = []
      resources.each do |res|
        # self.keywords is defined in MetricBase
        keywords << self.keywords[res.id][0..-2] # dont use the facebook id as a keyword, it might skew the results
      end

      keywords
    end

    def sort_value(value)
      if value.is_a?(Fixnum)
        value
      elsif value.has_key?('count') and value['count'].class.method_defined? :to_i
        value['count'].to_i
      else
        value
      end
    end

    def query_google_keywords(keywords)
      count = nil

      query_parameter = ""
      keywords.each do |group|
        query_parameter << '("' << group.join('"|"') << '") '
      end

      @logger.debug("Calling google with query: #{query_parameter}")

      url = "http://www.google.com/search?hl=en&q=#{URI.escape(query_parameter)}&filter=0&ie=utf-8&oe=utf-8&start=990"

      #begin
      count = get_hits_directly(url)
      #  count = get_hits_from_browser(url)
      #rescue GoogleCaptchaError => e
      #  Utility.log_exception(e)
      #  captcha_helper = GoogleCaptchaHelper.new(self.watir_browser)
      #  captcha_helper.solve_captcha

      #  count = get_hits_from_browser(url)
      #end

      { count: count, query: query_parameter }
    end

    def get_hits_from_browser(url)
      b = self.watir_browser
      @logger.debug "-- opening #{url}"

      begin
        b.goto url
      rescue Errno::ECONNREFUSED => exception
        clear_browser
        return get_hits_from_browser(url)
      end

      if b.div(id: "resultStats").exists?
        count_human = b.div(id: "resultStats").text.scan(/[0-9,\.]+/)

        return inner_html.map { |x| x.gsub(/[,\.]/, '').to_i }.max if count_human.length > 1
      end
      
      if b.url.index("sorry/IndexRedirect")
        raise GoogleCaptchaError
      end

      0
    end

    def watir_browser
      if @watir_browser.nil?
        begin
          require 'headless'
          @headless = Headless.new
          @headless.start
        rescue LoadError => e
        rescue Headless::Exception => e
        end

        @watir_browser = Watir::Browser.new
      end

      @watir_browser
    end

    def get_hits_directly(url)
      response = fetch(url)

      body = response.body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      html_count = body.match(/id\=\"resultStats\"\>[^\<]+/)

      if html_count.nil? or html_count.length == 0
        count = 0
        @logger.debug(Sanitize.clean(body, {:remove_contents => ["script","style"]})[0..1000])
      else
        inner_html = html_count[0].scan(/[0-9,\.]+/)
        
        if inner_html.nil? or inner_html.length == 0
          count = 0 
          @logger.debug(Sanitize.clean(body, {:remove_contents => ["script","style"]})[0..1000])
        else
          count = inner_html.map { |x| x.gsub(/[,\.]/, '').to_i }.max
        end
      end

      count
    end

    def fetch(uri_str, limit = 10)
      # You should choose a better exception.
      raise ArgumentError, 'too many HTTP redirects' if limit == 0

      @logger.debug "-- opening #{uri_str}"
      uri = URI(uri_str)
      req = Net::HTTP::Get.new(uri)

      req['User-Agent'] = 'ELinks/0.9.3 (textmode; Linux 2.6.9-kanotix-8 i686; 127x41)'
      req['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      req['Accept-Language'] = 'en-us,en'
      req['Accept-Encoding'] = 'Accept-Encoding: deflate'
      req['Cache-Control'] = 'max-age=0'

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case response
      when Net::HTTPSuccess then
        response
      when Net::HTTPRedirection then
        location = response['location']

        if location.index('sorry/IndexRedirect')
          # was detected
          @logger.warn "-- google detected bot activity, pause for #{wait_time} minutes"
          sleep wait_time * 60
          fetch(uri_str)
        else
          @logger.warn "redirected to #{location}"
          fetch(location, limit - 1)
        end
      else
        @logger.warn "-- Unknown response status: #{response.class}"
        response
      end
    end

    def wait_time
      5
    end
  end
end