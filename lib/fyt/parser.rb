# frozen_string_literal: true

require 'rss'

module FYT
  # reads and prepares a youtube feed for further processing
  class Parser < FYT::Base
    def initialize(url, proxy_manager)
      @url = url
      @proxy_manager = proxy_manager
    end

    def read
      proxy = @proxy_manager.get!

      open(@url, proxy: 'http://' + proxy.url) do |rss|
        return RSS::Parser.parse(rss, false)
      end
    rescue
      @proxy_manager.remove(proxy)

      read if @proxy_manager.proxies.size > 0
    end
  end
end
