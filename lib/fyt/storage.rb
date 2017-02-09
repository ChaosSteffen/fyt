# frozen_string_literal: true
module FYT
  # Manages file downloads and storage
  class Storage < FYT::Base
    def initialize(path, format_options, output_format)
      @path = path || ''
      @format_options = format_options
      @output_format = output_format
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
      options = [
        "-f '#{@format_options}'",
        "--merge-output-format '#{@output_format}'",
        "-o '#{output_path}'",
        "'#{url}'"
      ].join(' ')

      logger.debug "Executing: youtube-dl #{options}"

      raise unless system("youtube-dl #{options}", out: $stdout, err: :out)
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
