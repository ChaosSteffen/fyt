# frozen_string_literal: true
require_relative 'fyt/base'
require_relative 'fyt/builder'
require_relative 'fyt/config'
require_relative 'fyt/parser'
require_relative 'fyt/storage'
require_relative 'fyt/storage_helper'
require_relative 'fyt/s3_storage'

require 'fileutils'

require 'proxy_fetcher'
require 'aws-sdk-s3'

module ProxyFetcher
  class Manager
    def remove(proxy)
      @proxies = @proxies - [proxy]
    end
  end
end

# handles the general behaviour of FYT
module FYT
  def self.lock
    lockfile = ENV['HOME'] + '/.fyt/pid.lock'
    dirname = File.dirname(lockfile)

    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    File.open(lockfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
      f.write(Process.pid.to_s)
    end

    at_exit { File.delete(lockfile) if File.exist?(lockfile) }
  end

  def self.run
    config = FYT::Config.new
    manager =
      ProxyFetcher::Manager.new(filters: { country: 'DE', maxtime: '500' })

    case config[:storage_type]
    when :local
      storage = FYT::S3Storage.new(
        config[:storage_path],
        config[:format_options],
        config[:output_format],
        manager
      )
    when :aws
      storage = FYT::S3Storage.new(
        config[:tmp_path],
        config[:format_options],
        config[:output_format],
        manager
      )

      Aws.config.update(
        credentials: Aws::Credentials.new(
          config[:aws][:access_key], config[:aws][:secret_key]
        )
      )
    else
      raise 'no storage_type configured'
    end

    config[:feeds].each do |feed_config|
      source_feed = FYT::Parser.new(feed_config[:url], manager).read

      new_feed = FYT::Builder.new(source_feed, storage, config[:server_prefix], manager).build

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
