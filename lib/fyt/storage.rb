# frozen_string_literal: true

module FYT
  # Manages file downloads and storage
  class Storage < FYT::Base
    def initialize(path, format_options, output_format, proxy_manager)
      @path = path || ''
      @format_options = format_options
      @output_format = output_format
      @proxy_manager = proxy_manager
      @known_files = []
    end

    def add(item)
      url = item.link.href

      path = path_for(item)
      download_file!(url, path)
      @known_files << File.basename(path)
      File.basename(path)
    end

    def add_feed(name, feed)
      logger.debug feed.to_s
      logger.debug @known_files

      File.join(@path, "#{name}.feed.rss20.xml").tap do |path|
        File.write(path, feed)

        @known_files << File.basename(path)
      end
    end

    def cleanup!
      logger.debug 'Files to delete:'
      logger.debug files_to_delete

      files_to_delete.each do |filename|
        delete_file! filename
      end
    end

    def mtime(filename)
      File.mtime(File.join(@path, filename))
    end

    def size(filename)
      File.size(File.join(@path, filename))
    end

    private

    def download_file!(url, output_path)
      proxy = @proxy_manager.get!

      options_string = [
        "-f '#{@format_options}'",
        "--merge-output-format '#{@output_format}'",
        "-o '#{output_path}'",
        "--proxy 'http://#{proxy.url}'",
        "'#{url}'"
      ].join(' ')

      logger.debug "Executing: youtube-dl #{options_string}"

      execute "timeout --preserve-status 300 youtube-dl #{options_string}"
    rescue
      @proxy_manager.remove(proxy)

      download_file!(url, output_path) unless @proxy_manager.proxies.empty?
    end

    def execute(command_string)
      IO.pipe do |read_io, write_io|
        break if system(command_string, out: write_io, err: write_io)

        write_io.close
        logger.debug read_io.read
        raise
      end
    end

    def delete_file!(filename)
      File.join(@path, filename).tap do |path|
        logger.debug "Deleting file: #{path}"
        File.delete(path)
      end
    end

    def filename_for(item)
      "#{item.id.content}.mp4"
    end

    def path_for(item)
      File.join(@path, filename_for(item))
    end

    def files_on_disk
      Dir.entries(@path).reject { |filename| filename.start_with? '.' }
    end

    def files_to_delete
      files_on_disk - @known_files
    end
  end
end
