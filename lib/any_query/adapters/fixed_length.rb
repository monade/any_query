# frozen_string_literal: true

module AnyQuery
  module Adapters
    # @api private
    class FixedLength < Base
      # @api private
      class Config < Base::Config
        def to_h
          {
            url: @url,
            primary_key: @primary_key,
            table: @table
          }
        end
      end

      def initialize(config)
        super(config)
        @file = File.open(url)
      end

      def parse_fields(model)
        @file.each_line.map do |line|
          result = {}
          last_index = 0
          model.fields.each do |name, field|
            raw_value = line[last_index...(last_index + field[:length])]
            result[name] = parse_field(field, raw_value)
            last_index += field[:length]
          end
          result
        end
      end

      def url
        @config[:url]
      end

      def load(model, select:, joins:, where:, limit:)
        @file.rewind

        chain = parse_fields(model)
        chain = fallback_where(chain, where) if where.present?
        chain = chain.first(limit) if limit.present?
        chain = resolve_joins(chain, joins) if joins.present?

        chain.map! { |row| instantiate_model(model, row) }
        chain = resolve_select(chain, select) if select.present?

        chain
      end

      def resolve_joins(data, joins)
        joins.map do |join|
          resolve_join(data, join)
        end
        data
      end

      def parse_field(field, line)
        result = parse_field_type(field, line)
        if field[:transform]
          field[:transform].call(result)
        else
          result
        end
      end
    end
  end
end
