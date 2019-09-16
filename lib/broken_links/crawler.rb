# frozen_string_literal: true

require 'broken_links'
require 'broken_links/status'
require 'broken_links/page'
require 'broken_links/login'

require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'
require 'colorize'
require 'whirly'
require 'json'

module BrokenLinks
  class Crawler
    FAKE_USER_AGENT =
      'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36'

    #
    # Initializes the Crawler object
    #
    # @param [params] params hash containing the params
    #
    def initialize(params)
      @semaphore = Mutex.new
      @max_threads = 4

      @login_url = params[:login_url]
      @username = params[:username]
      @password = params[:password]

      @print_json = params[:json]
      @print = params[:print]
      @visited = [] # Array of URLs
      @pages = [] # Array of BrokenLinks::Page

      @cookies = if @login_url && @username && @password
                   BrokenLinks::Login.new(login_url: @login_url, username: @username, password: @password).do_login
                 end

      # Enqueue base url
      @start_resource = BrokenLinks::Page.new(url: params[:url])
    rescue StandardError => e
      puts e.message + e.backtrace
    end

    def start
      Whirly.start spinner: 'dots'
      threads = []
      can_spawn_thread?
      threads << visit(@start_resource.url)
      threads.each(&:join)
      Whirly.stop

      print_results if @print
      print_json if @print_json
    end

    def visit(url)
      Thread.new do
        Whirly.status = "Visiting #{url}".blue
        new_page = @semaphore.synchronize { BrokenLinks::Page.new(url: url) }
        response = get_response(new_page.uri)
        new_page.status = response ? validate_uri(new_page.uri, response) : BrokenLinks::Status::Error.new(error: 'Unknown Response')

        @semaphore.synchronize do
          @pages << new_page
        end

        is_different_host = new_page.uri.host != @start_resource.uri.host
        is_dead = new_page.status.is_a? BrokenLinks::Status::Error

        parse_links(new_page, response) unless is_different_host || is_dead
      end
    end

    def parse_links(new_page, response)
      threads = []
      Whirly.status = "Getting links from  #{new_page.url}".blue

      get_uris(new_page, response.body).each do |new_uri|
        uri_s = new_uri.to_s

        @semaphore.synchronize { new_page.links << uri_s unless new_page.links.include? uri_s }
        next if @visited.include?(uri_s)

        @semaphore.synchronize { @visited << uri_s }
        can_spawn_thread?
        threads << visit(uri_s)
      end
      threads.each(&:join)
    end

    #
    # Creates an HTTP GET request and returns the resource
    #
    # @param URI uri
    #
    # @return Boolean / Request Returns the resource or false if it fails
    #
    def get_response(uri)
      http_options = { use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 20 }
      request = Net::HTTP::Get.new(uri)
      Net::HTTP.start(uri.host, uri.port, http_options) do |http|
        # Act normal
        # Pretend you are a person
        # Send cookies if you have them
        request['Cookie'] = @cookies unless @cookies.nil?
        request['User-Agent'] = FAKE_USER_AGENT
        http.request(request)
      end
    rescue StandardError
      false
    end

    #
    # Checks the response code to see if it's valid or not
    # If it's a redirection, it builds up the redirect url and validates it
    #
    # @param <URI> uri URI related to the response
    # @param <Response> response Response object from HTTP::Response
    # @param <Response> response Response object from HTTP::Response
    #
    # @return <Boolean> Returns if the URL is alive or dead
    #
    def validate_uri(uri, response, redirected = false)
      if response.is_a? Net::HTTPSuccess
        redirected ? BrokenLinks::Status::Redirected.new(redirected_to: uri.to_s) : BrokenLinks::Status::OK.new
      elsif response.is_a? Net::HTTPRedirection
        redirect_uri = build_uri(uri, response['location'])
        validate_uri(redirect_uri, get_response(redirect_uri), true)
      else
        BrokenLinks::Status::Error.new(error: 'Unknown Response')
      end
    end

    #
    # Parses the HTML and grabs hrefs from <a> that contains
    # relative paths or full URLS but not mailto:
    #
    # @param Page current_page Page we are currently crawling
    # @param Response response Response object from HTTP::Response
    #
    # @return [List of URIs] Array containing the URIs we crawled
    #
    def get_uris(current_page, response)
      Nokogiri.HTML(response).css('a').reject do |link|
        link.attribute('href').nil? ||
          link.attribute('href').value =~ /mailto\:/ ||
          link.attribute('href').value == '#'
      end.map { |link| build_uri(current_page.uri, link.attribute('href').value.strip) }.uniq
    end

    #
    # Builds a new URI wether it's absolute or relative
    #
    # @param <URI> base_uri URI we are currently crawling
    # @param <String> url the URL to join
    #
    # @return <URI> Returns a fully build URI
    #
    def build_uri(base_uri, url)
      url =~ %r{^https?\://} ? URI(url) : URI.join(base_uri, url)
    end

    #
    # Prints the results to the console
    #
    def print_results
      puts '----------REPORT------------'.blue

      @pages.each do |page|
        puts '--------------'
        puts page.url
        puts page.status.print
        puts '--- You can find the link in: ----'
        @pages.each { |p| puts p.url if p.links.include? page.url }
      end

      errored_count = @pages.filter { |x| x.status.is_a? BrokenLinks::Status::Error }.count
      puts ''
      puts '----------------------'.blue
      puts "#{@pages.count} links found".yellow
      puts "#{@pages.count - errored_count} good links".green
      puts "#{errored_count} broken links".red
      puts '----------------------'.blue
    end

    #
    # Prints the results in json format
    #
    def print_json
      result = []
      @pages.each do |page|
        status = page.status.to_hash
        obj = { url: page.url, status: status[:status] }
        obj[:found_in] = @pages.map { |p| p.url if p.links.include?(page.url) }.compact
        result << obj
      end
      result.to_json
    end

    def can_spawn_thread?
      until Thread.list.select { |thread| thread.status == 'run' }.count <
            (1 + @max_threads)
        sleep 0.015
      end
    end
  end
end
