# frozen_string_literal: true

require 'rss'

module FYT
  # reads and prepares a youtube feed for further processing
  class Parser < FYT::Base
    def initialize(url)
      @url = url
    end

    def read
      open(@url) do |rss|
        return RSS::Parser.parse(rss, false)
      end
    end
  end
end
