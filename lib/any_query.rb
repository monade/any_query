# frozen_string_literal: true

require 'httparty'
require 'active_support/all'
require 'active_record'
require 'active_model'

# AnyQuery is a library to help you build queries for different data sources
module AnyQuery
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Adapters
  autoload :Query

  included do
    delegate_missing_to :@attributes
  end

  def initialize
    @attributes = OpenStruct.new
  end

  module ClassMethods
    def adapter(name, &block)
      config = "AnyQuery::Adapters::#{name.to_s.classify}::Config".constantize.new(&block)
      @adapter = "AnyQuery::Adapters::#{name.to_s.classify}".constantize.new(config)
    end

    delegate_missing_to :all

    # @return [AnyQuery::Adapters::Base]
    def _adapter
      @adapter
    end

    # @param [Symbol] name
    # @param [Hash] options
    # @option options [Symbol] :type
    # @option options [String] :format
    # @option options [Integer] :length
    # @option options [Proc] :transform
    def field(name, options = {})
      fields[name] = options
    end

    # @return [Hash]
    def fields
      @fields ||= {}
    end

    # @return [AnyQuery::Query]
    def all
      Query.new(self, @adapter)
    end
  end
end
