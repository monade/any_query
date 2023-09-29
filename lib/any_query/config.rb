# frozen_string_literal: true

module AnyQuery
  # A class to handle configuration for AnyQuery
  class Config
    def self.logger
      @logger ||= Logger.new($stdout)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
