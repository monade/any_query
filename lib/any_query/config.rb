# frozen_string_literal: true

module AnyQuery
  # A class to handle configuration for AnyQuery
  class Config
    attr_writer :logger

    def self.logger
      @logger ||= Logger.new($stdout)
    end
  end
end
