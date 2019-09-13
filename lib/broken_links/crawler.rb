# frozen_string_literal: true

require 'broken_links'

require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'

module BrokenLinks
  class Page
    attr_reader :visited, :status, :links, :uri, :url
    attr_writer :visited, :status, :links

    def initialize(params)
      @url = params[:url]
      @uri = URI(@url)
      @visited = false
      @status = { alive: false }
      @links = []
    end
  end
  class Crawler
    FAKE_USER_AGENT = "Mozilla/5.0 (Linux; Android 8.0.0;) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.73 Mobile Safari/537.36"

    def initialize(params)
      @start_resource = BrokenLinks::Page.new(url: params[:url])
      @depth = params[:depth] || 10

      @queue = [@start_resource.uri]
      @visited = []
      @pages = []

      crawl_url
      print_results
    end


    # BFS
    def crawl_url
      while @queue.any?
        url = @queue.shift
        new_page = BrokenLinks::Page.new(url: url)

        response = get_response(new_page.uri)
        puts response
        if response
          status = validate_uri(new_page.uri, response)
        else
          status = false
        end

        new_page.status[:alive] = status

        @pages << new_page
        @visited << url

        next if new_page.uri.host != @start_resource.uri.host || !status

        get_links(new_page.uri, response.body).each do |new_uri|
          uri_s = new_uri.to_s

          # @visited.each do |v|
          #   puts "-------"
          #   puts v
          #   puts uri_s
          #   puts "IGUALES" if v == uri_s
          #   puts "DISTINTOS" if v != uri_s

          #   puts "-------"

          # end

          unless new_page.links.include? uri_s
            new_page.links << uri_s
          end

          # puts @visited.include?(uri_s)
          # puts "-INCLUDE #{uri_s}-"

          if !@visited.include?(uri_s) && !@queue.include?(uri_s)
            @queue << uri_s
          end
        end
    end

    rescue StandardError => e
      puts e
    end

    def get_response(uri)
      begin
        http_options = {
          use_ssl:      uri.scheme == "https",
        }
        request = Net::HTTP::Get.new(uri)
        Net::HTTP.start(uri.host, uri.port, http_options) do |http|
          request["User-Agent"] = FAKE_USER_AGENT
          http.request(request)
        end
      rescue => exception
        puts exception
        false
      end

    end

    def validate_uri(uri,response)
      begin
        if response.is_a? Net::HTTPSuccess then true
        elsif response.is_a? Net::HTTPRedirection
          redirect_uri = build_uri(uri, response['location'])
          puts redirect_uri
          return self.validate_uri(uri, get_response(redirect_uri))
        else false
        end
      rescue  StandardError => e
        puts e
          false
      end
    end

    def get_links(current_uri, response)

      links = Nokogiri::HTML(response)
              .css('a')
              .reject { |link| link.attribute('href').nil? ||
                link.attribute('href').value =~ /mailto\:/ ||
                link.attribute('href').value == "#"  }
              .map { |link| link.attribute('href').value.strip }
              .uniq


      links.map { |url| build_uri(current_uri, url) }
    end

    def build_uri(current_url, url)
      if url =~ %r{^https?\://}
        URI(url)
      else
        URI.join(current_url, url)
      end
    end

    def print_results
      @pages.each do |page|
        puts "#{page.url} #{page.status[:alive] ? "[OK]" : "[DEAD]"}"
        page.links.each do |link|
          puts "--------#{link}"
        end
      end
    end

    def self.find(_url, _depth)
      'pass!'
    end
  end
end
