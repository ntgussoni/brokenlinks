# frozen_string_literal: true

require 'thor'
require 'broken_links'

module BrokenLinks
  class CLI < Thor
    desc 'find', 'Finds links recursively'
    method_option :url, aliases: '-u', required: true, type: :string
    method_option :depth, aliases: '-d', default: 10, type: :numeric
    def find
      url = options[:url]
      depth = options[:url]

      puts BrokenLinks::Crawler.new(url: url, depth: depth)
    end
  end
end
