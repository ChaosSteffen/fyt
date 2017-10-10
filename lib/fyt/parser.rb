# frozen_string_literal: true

require 'rss'

module FYT
  # reads and prepares a youtube feed for further processing
  class Parser < FYT::Base
    def initialize(url, proxy)
      @url = url
      @proxy = proxy
    end

    def read
      open(@url, proxy: 'http://' + @proxy.url) do |rss|
        return RSS::Parser.parse(rss, false)
      end
    end
  end
end
