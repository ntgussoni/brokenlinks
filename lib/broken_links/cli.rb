# frozen_string_literal: true

require 'thor'
require 'broken_links'

module BrokenLinks
  class CLI < Thor
    desc '', 'Finds links recursively'
    method_option :url, aliases: '-u', required: true, type: :string
    method_option :json, default: false, type: :boolean
    method_option :print, aliases: '--p', default: true, type: :boolean
    method_option :depth, aliases: '-d', default: 10, type: :numeric

    def find
      url = options[:url]
      depth = options[:depth]
      o_print = options[:print]
      json = options[:json]

      puts BrokenLinks::Crawler.new(url: url, depth: depth, print: o_print, json: json).start
    end

    default_task :find
  end
end
