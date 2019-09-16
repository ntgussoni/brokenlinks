# frozen_string_literal: true

require 'broken_links'
require 'net/http'

#
# This class aims to implement a basic authentication & cookie retrieval method
# If the site relies on cookies, this should work for all of the following requests
# But this is by no means a solution for every site
#
# If the site uses tokens, like JWT, then this implementation could vary a lot.
# It could be as easy as retrieving the token sent in the header after the first request
# Or if the token refreshes on each request, it should be necessary to update it for each following ones.
#
# We could also have CRSF protections, with anti-forgery tokens changing on each page render.
# That's something to have in mind too and it would require to send extra data with each request.
#

module BrokenLinks
  class Login
    def initialize(params)
      @login_uri = URI(params[:login_url])
      @username = params[:username]
      @password = params[:password]
    rescue StandardError => e
      puts e.message
      puts e.backtrace
    end

    def do_login
      http_options = { use_ssl: @login_uri.scheme == 'https' }
      ## Fake a get request to the login page
      request = Net::HTTP::Get.new(@login_uri)
      response = Net::HTTP.start(@login_uri.host, @login_uri.port, http_options) do |http|
        # Act normal
        # Pretend you are a person
        request['User-Agent'] = BrokenLinks::Crawler::FAKE_USER_AGENT
        http.request(request)
      end

      cookies = parse_cookies(response)

      headers = {
        'Cookie' => cookies,
        'Referer' => @login_uri.to_s, # Make it believe the request is coming from the login page
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
      request = Net::HTTP::Post.new(@login_uri)

      # Again, this might not be the real scenario
      request.set_form_data(username: @username, password: @password)
      response = Net::HTTP.start(@login_uri.host, @login_uri.port, http_options) do |http|
        # Act normal
        # Pretend you are a person
        request['User-Agent'] = BrokenLinks::Crawler::FAKE_USER_AGENT
        http.request(request)
      end

      if response.is_a? Net::HTTPSuccess
        # If everything went well, we return the cookies
        parse_cookies(response)
      else
        puts 'Could not login or find cookies'.red
      end
    end

    def parse_cookies(response)
      # The server might return multiple cookies
      # [0] is kind of arbitrary, it depends on the cookies from the response
      # The cookies should probably be passed from outside BrokenLinks,
      # since it's an implementation detail which is bigger and more complex to be
      # handled in this this crawler
      cookies = response.get_fields('set-cookie')
      resulting_cookies = []
      cookies.each do |cookie|
        resulting_cookies.push(cookie.split('; ')[0])
      end
      resulting_cookies.join('; ')
    end
  end
end
