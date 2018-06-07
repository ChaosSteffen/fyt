# frozen_string_literal: true

require 'aws-sdk-s3'

module FYT
  # Manages file downloads and storage
  class S3Storage < FYT::Base
    def initialize(tmp_path, format_options, output_format, proxy_manager)
      @tmp_path = tmp_path || ''
      @format_options = format_options
      @output_format = output_format
      @proxy_manager = proxy_manager
      @known_files = []
    end

    def add(item)
      url = item.link.href

      filename_for(item).tap do |filename|
        unless files_on_s3.include? filename
          download_file!(url, filename)
          upload_to_s3(filename)
          delete_file_from_disk(filename)
        end

        @known_files << filename
      end
    end

    def add_feed(feedname, feed)
      logger.debug feed.to_s
      logger.debug @known_files

      feed_filename = "#{feedname}.feed.rss20.xml"

      tmp_path_for(feed_filename).tap do |path|
        File.write(path, feed)
        upload_to_s3(feed_filename)
        delete_file_from_disk(feed_filename)
        @known_files << feed_filename
      end
    end

    def cleanup!
      logger.debug 'Files to delete:'
      logger.debug files_to_delete

      files_to_delete.each do |filename|
        delete_from_s3 filename
      end
    end

    def mtime(filename)
      bucket.object(filename).last_modified
    end

    def size(filename)
      bucket.object(filename).content_length
    end

    private

    def download_file!(url, filename)
      proxy = @proxy_manager.get!

      command = "#{timeout_cmd} #{youtube_dl_cmd(proxy, url, filename)}"
      logger.debug "Executing: #{command}"

      begin
        execute command
      rescue
        @proxy_manager.remove(proxy)

        download_file!(url, filename) unless @proxy_manager.proxies.size.empty?
      end
    end

    def execute(command_string)
      IO.pipe do |read_io, write_io|
        break if system(command_string, out: write_io, err: write_io)

        write_io.close
        logger.debug read_io.read
        raise
      end
    end

    def delete_file_from_disk(filename)
      tmp_path_for(filename).tap do |path|
        logger.debug "Deleting file: #{path}"
        File.delete(path)
      end
    end

    def filename_for(item)
      "#{item.id.content}.mp4"
    end

    def files_to_delete
      files_on_s3 - @known_files
    end

    def files_on_s3
      bucket.objects.limit(100).map(&:key)
    end

    def upload_to_s3(filename)
      bucket.object(filename).upload_file(
        tmp_path_for(filename), acl: 'public-read'
      )
    end

    def delete_from_s3(name)
      bucket.object(name).delete
    end

    def tmp_path_for(filename)
      File.join(@tmp_path, filename)
    end

    def bucket
      Aws::S3::Resource
        .new(region: 'eu-central-1')
        .bucket('fyt-storage')
    end

    def timeout_cmd
      if system('which timeout', out: '/dev/null')
        return 'timeout --preserve-status 300'
      end

      raise unless system('which gtimeout', out: '/dev/null')

      'gtimeout --preserve-status 300'
    end

    def youtube_dl_cmd(proxy, url, filename)
      [
        'youtube-dl',
        "-f '#{@format_options}'",
        "--merge-output-format '#{@output_format}'",
        "-o '#{tmp_path_for(filename)}'",
        "--proxy 'http:#{proxy.url}'",
        "'#{url}'"
      ].join(' ')
    end
  end
end
