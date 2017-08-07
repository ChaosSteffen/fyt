# frozen_string_literal: true
require_relative 'fyt/base'
require_relative 'fyt/builder'
require_relative 'fyt/config'
require_relative 'fyt/parser'
require_relative 'fyt/storage'

require 'rss'

# handles the general behaviour of FYT
module FYT
  def self.run
    config = FYT::Config.new
    storage = FYT::Storage.new(
      config[:storage_path],
      config[:format_options],
      config[:output_format],
      config[:proxy]
    )

    config[:feeds].each do |feed_config|
      source_feed = FYT::Parser.new(feed_config[:url]).read

      new_feed = FYT::Builder.new(source_feed, storage, config[:server_prefix]).build

      storage.add_feed(feed_config[:name], new_feed)
    end

    storage.cleanup!
  end

  def self.config
    config = FYT::Config.new

    print "Please enter storage path [#{config[:storage_path]}]: "
    config[:storage_path] = STDIN.gets.rstrip

    print "Please enter server prefix [#{config[:server_prefix]}]: "
    config[:server_prefix] = STDIN.gets.rstrip

    print "Please enter format options [#{config[:format_options]}]: "
    config[:format_options] = STDIN.gets.rstrip

    print "Please enter output_format [#{config[:output_format]}]: "
    config[:output_format] = STDIN.gets.rstrip
  end

  def self.add
    print 'Please name of the feed e.g. "My Favorite Videos": '
    name = STDIN.gets.rstrip

    print 'Please enter feed url e.g. "https://www.youtube.com/feeds/videos.xml?channel_id=AbCdEf1234567890aBcDeF00": '
    url = STDIN.gets.rstrip

    raise 'No name given' if name.size.zero?
    raise 'No feed url given' if url.size.zero?

    config = FYT::Config.new
    feeds = config[:feeds]
    feeds << { name: name, url: url }
    config[:feeds] = feeds
  end
end
