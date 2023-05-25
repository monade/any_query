# frozen_string_literal: true

module AnyQuery
  # @api private
  module Adapters
    extend ActiveSupport::Autoload
    autoload :Base
    autoload :Http
    autoload :Sql
    autoload :FixedLength
    autoload :Csv
  end
end
