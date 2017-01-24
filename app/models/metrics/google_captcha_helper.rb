require 'watir-webdriver'
require 'open-uri'
#require 'rest_client'

module Metrics
  class GoogleCaptchaHelper
    def initialize(browser = nil)
      @watir_browser = browser
    end

    def solve_captcha
      b = watir_browser

      load_form(b)

      counter = 0
      code = ""
      begin
        sleep 60
        counter += 1

        code = File.read("#{Rails.root}/tmp/captcha-code.txt")
        break unless code.blank? or code.length < 5
      end while counter <= 60

      success = false
      unless code.blank? or code.length < 5
        success = enter_code(b, code)
      else
        Rails.logger.warn "Did not read a valid code during 5 minutes"
      end

      clear_browser
      success
    end

    def load_form(b)
      b.goto 'http://www.google.com/search?q=Memes' if b.url.index('sorry').nil?

      if b.url.index('sorry').nil? and b.div(id: 'resultStats').exists?
        raise 'Not on captcha page'
      end

      form_id = b.input(name: 'id').value
=begin
      @session[:captcha] ||= {}
      @session[:captcha][:form_id] = form_id
      @session[:captcha][:cookies] = b.cookies.to_a
      @session[:captcha][:user_agent] = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:25.0) Gecko/20100101 Firefox/25.0"
=end
      local_path = "/google-captcha-#{form_id}.png"
      b.screenshot.save "#{Rails.root}/public/#{local_path}"

      File.open("#{Rails.root}/tmp/captcha-image.txt", "w") do |io|
        io.write local_path
      end
      File.open("#{Rails.root}/tmp/captcha-code.txt", "w") do |io|
        io.write ""
      end
    end

    def enter_code(b, code)
      b.text_field(name: 'captcha').set code
      b.button(name: 'submit').click
      b.wait
b.screenshot.save "#{Rails.root}/public/google-screen.png"
      Rails.logger.info "After code submit on URL #{b.url}"
      b.url.index('sorry').nil?
    end

    def load_image
      File.read("#{Rails.root}/tmp/captcha-image.txt")
    end

    def save_code(code)
      File.open("#{Rails.root}/tmp/captcha-code.txt", "w") do |io|
        io.write code
      end
    end

=begin
    def post(code)
      #response = RestClient.get 'http://ipv4.google.com/sorry/CaptchaRedirect', params: { captcha: code, 
      #  id: @session[:captcha_form_id], continue: 'http://www.google.com/', submit: 'Submit'}

      cookies = ""
      @session[:captcha][:cookies].each do |cookie|
        cookies = "#{cookie[:name]}=#{cookie[:value]}"
      end

      RestClient.log = Rails.logger

      begin
        success = true
        response = RestClient.get(
          "http://ipv4.google.com/sorry/CaptchaRedirect?continue=http%3A%2F%2Fwww.google.com%2F&id=#{@session[:captcha][:form_id]}&captcha=#{code}&submit=Submit",
          { 
            "Cookies" => cookies,
            "User-Agent" => "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:25.0) Gecko/20100101 Firefox/25.0",
            "Accept" => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            "Accept-Language" => 'en-US,en;q=0.5',
            "Accept-Encoding" => "gzip, deflate",
            "Referer" => "http://ipv4.google.com/sorry/CaptchaRedirect",
            "Connection" => "keep-alive",
            "Host" => "ipv4.google.com"
          }
        )
      rescue RestClient::ServiceUnavailable => exception
        success = false
      end
      b = watir_browser
      b.goto 'http://ipv4.google.com/sorry/CaptchaRedirect'

      script = "return arguments[0].value = '#{@session[:captcha][:form_id]}'"
      b.execute_script(script, b.input(name: 'id'))
      b.cookies.clear

      @session[:captcha][:cookies].each do |cookie|
        b.cookies.add cookie[:name], cookie[:value], domain: cookie[:domain]
      end
      
      b.text_field(name: 'captcha').set code

      b.button(name: 'submit').click
      success = b.url.include?('sorry').nil?
      File.delete("#{Rails.root}/public/google-captcha-#{@session[:captcha][:form_id]}.png")
      
      clear_browser
      success
    end
=end

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

    def clear_browser
      unless @watir_browser.nil?
        @watir_browser.close
        @headless.destroy if @headless

        @watir_browser = nil
        @headless = nil
      end
    end
  end
end
