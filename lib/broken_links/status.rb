# frozen_string_literal: true

require 'broken_links'
require 'colorize'
#
# This class holds the basic information of every page visited
#
module BrokenLinks
  class Status
    class Base
    end

    #
    # OK Class to handle the Success status
    #
    class OK < Base
      def print
        '[OK]'.green
      end

      def to_hash
        { status: 'ok' }
      end
    end

    #
    # Redirected Class to handle the redirection status
    #
    class Redirected < OK
      def initialize(params)
        @redirected_to = params[:redirected_to]
      end

      def print
        "[REDIRECTED] -> #{@redirected_to}".yellow
      end
    end

    #
    # Error Class to handle the 404 or any other error status
    #
    class Error < Base
      def initialize(params)
        @error = params[:error]
      end

      def print
        "[ERROR] - #{@error}".red
      end

      def to_hash
        { status: 'error' }
      end
    end
  end
end
