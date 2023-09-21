# frozen_string_literal: true

module AnyQuery
  class Client
    def initialize(adapter:, params: {})
      config = "AnyQuery::Adapters::#{adapter.to_s.classify}::Config".constantize.new(params)
      @adapter = "AnyQuery::Adapters::#{adapter.to_s.classify}".constantize.new(config)
      @params = params
      @fields = {}

      @params[:fields]&.each do |name, options|
        @fields[name] = options
      end
    end

    delegate_missing_to :all

    def all
      Query.new(ResultFactory.new(@fields), @adapter)
    end

    class Result
      def initialize
        @attributes = OpenStruct.new
      end

      delegate_missing_to :@attributes
    end

    # A class to instantiate results
    class ResultFactory
      attr_reader :fields

      def initialize(fields)
        @fields = fields
      end

      def new
        Result.new
      end
    end
  end
end
