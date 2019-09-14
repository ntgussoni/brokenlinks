# frozen_string_literal: true

require 'broken_links'

module BrokenLinks
  #
  # This class holds the basic information of every page visited
  #
  class Page
    attr_reader :visited, :status, :links, :uri, :url
    attr_writer :visited, :status, :links

    def initialize(params)
      @url = params[:url]
      @uri = URI(@url)
      @visited = false
      @status = nil
      @links = []
    end
  end
end
