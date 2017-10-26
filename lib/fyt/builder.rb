# frozen_string_literal: true
module FYT
  # processes the Youtube feed
  class Builder < FYT::Base
    def initialize(source_feed, storage, server_prefix, proxy_manager)
      @source_feed = source_feed
      @storage = storage
      @server_prefix = server_prefix
      @proxy_manager = proxy_manager
      @maker = RSS::Maker['2.0'].new
    end

    def build
      add_channel_data(@source_feed.link.href, @source_feed.title.content)
      add_image(@source_feed.author.uri.content, @source_feed.title.content)

      build_items

      @maker.to_feed
    end

    private

    def build_items
      @source_feed.items.each do |item|
        filename = @storage.add(item)

        add_item(item.link.href, item.title.content, filename)
      end
    end

    def add_channel_data(link, title)
      logger.debug "Title: #{title}"

      @maker.channel.updated = Time.now.to_s
      @maker.channel.link = link
      @maker.channel.title = title
      @maker.channel.description = 'Processed Youtube Feed'
    end

    def add_image(youtube_url, title)
      proxy = @proxy_manager.get!
      youtube_url = youtube_url.gsub('http:', 'https:')

      open(youtube_url, proxy: 'http://' + proxy.url) do |file|
        image_url =
          file.read.scan(/<meta property=\"og:image\" content=\"(.*)\">/)
              .flatten.first

        @maker.image.url = image_url
        @maker.image.title = title
      end
    rescue OpenURI::HTTPError => e
      logger.debug "OpenURI::HTTPError: #{e.message}"
    rescue
      @proxy_manager.remove(proxy)

      add_image(youtube_url, title) if @proxy_manager.proxies.size > 0
    end

    def add_item(link, title, filename)
      @maker.items.new_item do |new_item|
        new_item.link = link
        new_item.title = title
        new_item.updated = @storage.mtime(filename)
        new_item.enclosure.url = "#{@server_prefix}/#{filename}"
        new_item.enclosure.type = 'video/mp4'
        new_item.enclosure.length = @storage.size(filename)
      end
    end
  end
end
