# frozen_string_literal: true

require 'csv'

module AnyQuery
  module Adapters
    class Csv < Base
      class Config < Base::Config
        def to_h
          {
            url: @url,
            primary_key: @primary_key,
            table: @table
          }
        end
      end

      def parse_fields(model)
        CSV.foreach(url, headers: true).map do |line|
          result = {}
          model.fields.each do |name, field|
            result[name] = parse_field(field, line[field[:source] || name.to_s])
          end
          result
        end
      end

      def url
        @config[:url]
      end

      def load(model, select:, joins:, where:, limit:)
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
