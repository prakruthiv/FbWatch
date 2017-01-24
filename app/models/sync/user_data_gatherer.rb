require 'json'
require 'cgi'
require 'uri'
require 'date'

module Sync
  class UserDataGatherer < FacebookGraph
    attr_writer :page_limit
    attr_reader :no_of_queries, :username

    def initialize(resource, facebook)
      super(facebook)

      @resource = resource
      @username = resource.username
      
      @no_of_queries = 0
      
      @page_limit = nil
      @error = nil

      @resume_path = ""
      
      @posts = []  

      self.logger = Logger.new("#{Rails.root}/log/resources/#{@username}.log")
    end

    def flash
      @flash ||= {alert: [], notice: []}
    end

    def fetch(pages = nil)
      @max_feed_pages = pages

      fetch_basic_data

      fetch_feed if @error.nil?

      self.logger.info "** Finished syncing with #{@no_of_queries} calls, error: #{@error.inspect}, resume path: #{@resume_path.inspect}, no of posts: #{@posts.length}"

      {
        basic_data: @basic_data,
        feed: @posts,
        resume_path: @resume_path,
        error: @error
      }
    end

    private
      def fetch_feed
        scan_feed(graph_link: @resource.resume_query, pages: @max_feed_pages)
      end

      def fetch_basic_data
        begin
          basic_data = self.facebook.get_object(@resource.facebook_id)
        rescue => exception
          @error = exception
        end
        
        if basic_data.blank?
          error_msg = "Unable to retrieve basic information for #{@username}, result was empty" 
          logger.warn error_msg
          @error = StandardError.new(error_msg) if @error.nil?
        end

        @basic_data = basic_data
      end

      def save_post(post)
        @posts << post
      end

      def set_graph_path_to_resume(path)
        @resume_path = path
      end

      def scan_feed(options)
        @feed_pager = FacebookCrawler.new(start: options[:graph_link] || '', base: "#{@resource.facebook_id}/feed", koala: facebook, logger: self.logger, page_limit: @page_limit)
        
        pages = options[:pages] || -1

        # clear global states when starting a scan
        @error = nil
        
        while true
          page_result = fetch_feed_page(@feed_pager)

          break if page_result[:status] != QUERY_SUCCESS

          pages -= 1
          if pages == 0
            # save the next call to resume sync
            set_graph_path_to_resume(@feed_pager.next_path)
            break
          end
        end

        @no_of_queries += @feed_pager.query_count
      end

      QUERY_SUCCESS = "QUERY_SUCCESS"
      QUERY_ERROR = "QUERY_ERROR"
      QUERY_END = "QUERY_END"

      def fetch_feed_page(pager)
        status = nil

        result = pager.next

        # query issue
        if result.is_a?(StandardError)
          Rails.logger.warn "Query issue for call '#{pager.last_path}'"
          set_graph_path_to_resume(pager.last_path)
          @error = result
          status = QUERY_ERROR
        end

        # end of data 
        status = QUERY_END if result_is_empty(result)
        
        if status.nil?
          # get comments and likes
          result['data'].each do |entry|
            post_result = fetch_full_post(entry)

            if post_result.is_a?(StandardError)
              build_resume_path_from_entry(entry)
              status = QUERY_ERROR 
              break
            end

            save_post(entry)
          end
        end
        
        if status == QUERY_ERROR
          Rails.logger.error "Error in resource #{@username}: #{@error.inspect}"

          flash[:alert] << result.to_yaml
        end 

        {
          result: result,
          status: status || QUERY_SUCCESS
        }
      end

      def fetch_full_post(entry)
        comments = get_all_comments(entry)
        if comments.is_a?(StandardError)
          return comments
        end

        likes = get_all_likes(entry)
        if likes.is_a?(StandardError)
          return likes
        end

        entry['comments'] = comments
        entry['likes'] = likes
      end

      def fetch_post_attribute_page(pager)
        status = nil

        result = pager.next

        # query issue
        if result.is_a?(StandardError)
          Rails.logger.warn "Query issue for call '#{pager.last_path}'"
          @error = result
          status = QUERY_ERROR
        end

        # end of data 
        status = QUERY_END if result_is_empty(result)
        
        if status.nil? and pager.on_posts?
          # get comments and likes
          result['data'].each do |entry|
            post_result = fetch_full_post(entry)

            if post_result.is_a?(StandardError)
              status = QUERY_ERROR 
              break
            end
          end
        end

        {
          result: result,
          status: status || QUERY_SUCCESS
        }
      end

      def scan_post_attribute(base, parameters)
        pager = FacebookCrawler.new(start: parameters, base: base, koala: facebook, logger: self.logger, page_limit: FacebookCrawler::MAX_LIMIT)

        attributes = []

        while true
          result = fetch_post_attribute_page(pager)

          return result[:result]  if result[:status] == QUERY_ERROR
          break                   if result[:status] == QUERY_END

          attributes.concat(result[:result]['data'])
        end

        @no_of_queries += pager.query_count
        
        {
          'count' => attributes.length,
          'data' => attributes
        }
      end

      def build_resume_path_from_entry(entry)
        entry_time = DateTime.strptime(entry['created_time'], "%Y-%m-%dT%H:%M:%S%z")

        time_modifier = @feed_pager.forward ? "until" : "since"

        set_graph_path_to_resume("/#{@resource.facebook_id}/feed?#{time_modifier}=#{entry_time.strftime("%s")}")
      end

      def fetch_connected_data(query, parameter)
        result = scan_post_attribute(query, parameter)

        if result.is_a?(StandardError)
          logger.debug "Stopping querying because encountered an error in sub-query"
        end

        return result
      end
      
      def get_all_comments(entry)
        if !entry.has_key?('comments') or !entry['comments'].is_a?(Hash) or !entry['comments'].has_key?('data') or entry['comments']['data'].length == 0
          return {
            'count' => 0,
            'data' => []
          }
        end
        
        fetch_connected_data(entry['id'] + '/comments', 'filter=stream')
      end
      
      def get_all_likes(entry)
        if !entry.has_key?('likes') and (!entry.has_key?('like_count') or entry['like_count'] == 0)
          return {
            'count' => 0,
            'data' => []
          }
        end
        
        fetch_connected_data(entry['id'] + '/likes', nil)
      end
        
      def result_is_empty(result) 
        # if no paging array is present the return object is 
        # presumably empty
        result.blank? || !result.has_key?('paging')
      end
  end
end