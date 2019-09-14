# frozen_string_literal: true

require 'bundler/setup'
require 'broken_links/version'
require 'broken_links/cli'
require 'broken_links/crawler'

module BrokenLinks
  class Error < StandardError; end
end
