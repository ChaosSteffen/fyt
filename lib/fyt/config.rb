# frozen_string_literal: true

require 'yaml/store'

module FYT
  # reads and prepares a youtube feed for further processing
  class Config < FYT::Base
    def initialize(path = nil)
      path ||= File.join(Dir.home, '.fyt.config.yml')
      @store = YAML::Store.new(path)

      # populate defaults
      @store.transaction do
        @store[:storage_path] ||= 'storage'
        @store[:server_prefix] ||= 'https://localhost:2017'
        @store[:format_options] ||= '22+140'
        @store[:output_format] ||= 'mp4'
        @store[:feeds] ||= []

        @store.commit
      end
    end

    def [](key)
      @store.transaction { @store[key] }
    end

    def []=(key, value)
      return if value.is_a?(String) && value.size.zero?

      @store.transaction do
        @store[key] = value
      end
    end
  end
end
