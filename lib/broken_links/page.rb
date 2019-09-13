# frozen_string_literal: true

require 'broken_links'

module BrokenLinks
  class Page
    attr_reader :visited, :failed, :links, :uri, :url
    attr_writer :visited, :failed, :links

    def initialize(params)
      @url = params[:url]
      @uri = URI(@url)
      @visited = false
      @failed = false
      @links = []
    end
  end
end
