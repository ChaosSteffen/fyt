# frozen_string_literal: true

module FYT
  module StorageHelper
    private

    def execute(command_string)
      IO.pipe do |read_io, write_io|
        break if system(command_string, out: write_io, err: write_io)

        write_io.close
        logger.debug read_io.read
        raise
      end
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
