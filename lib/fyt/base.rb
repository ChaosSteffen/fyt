# frozen_string_literal: true
require 'logger'

module FYT
  # processes the Youtube feed
  class Base
    @@logger = nil

    def logger
      @@logger ||= Logger.new(STDOUT).tap do |logger|
        logger.level = Logger::DEBUG
      end
    end
  end
end
