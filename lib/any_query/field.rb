# frozen_string_literal: true

module AnyQuery
  # Represents a field in a query
  class Field
    attr_reader :name, :type, :options

    def initialize(name, type, options = {}); end
  end
end
