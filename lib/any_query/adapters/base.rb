# frozen_string_literal: true

module AnyQuery
  module Adapters
    # @api private
    # @abstract
    class Base
      def initialize(config)
        @config = config.to_h
      end

      def load(model, select:, joins:, where:, limit:)
        raise NotImplementedError
      end

      def load_single(model, id, joins)
        load(model, select: [], joins:, where: [{ id: }], limit: 1).first
      end

      def instantiate_model(model, record)
        instance = model.new
        attrs = instance.instance_variable_get(:@attributes)
        record.each do |key, value|
          attrs.send("#{key}=", value)
        end
        instance
      end

      def resolve_path(data, path)
        if path.is_a?(Proc)
          path.call(data)
        elsif path.is_a?(Array)
          data.dig(*path)
        else
          data[path]
        end
      rescue StandardError => e
        AnyQuery::Config.logger.error "Failed to resolve path #{path} on #{data.inspect}"
        raise e
      end

      def fallback_where(data, wheres)
        data.filter do |row|
          wheres.all? do |where|
            where.all? do |key, value|
              resolve_path(row, key) == value
            end
          end
        end
      end

      def resolve_join(data, join)
        AnyQuery::Config.logger.debug "Joining #{join[:model]} on #{join[:primary_key]} = #{join[:foreign_key]}"
        foreign_keys = data.map { |row| resolve_path(row, join[:foreign_key]) }.compact.uniq
        result = run_external_join(join, foreign_keys)

        result = group_join_data(result, join)

        data.each do |row|
          row[join[:into]] = result[resolve_path(row, join[:foreign_key])] || (join[:as] == :list ? [] : nil)
        end
      end

      def group_join_data(data, join)
        if join[:as] == :list
          data.group_by { |e| resolve_path(e, join[:primary_key]) }
        else
          data.index_by { |e| resolve_path(e, join[:primary_key]) }
        end
      end

      def run_external_join(join, foreign_keys)
        case join[:strategy]
        when Proc
          join[:strategy].call(foreign_keys)
        when :single
          map_multi_threaded(foreign_keys.uniq) { |key| join[:model].find(key) }
        when :full_scan
          join[:model].to_a
        else
          join[:model].where(id: foreign_keys).to_a
        end
      end

      def resolve_select(chain, select)
        chain.map do |record|
          select.map do |field|
            resolve_path(record, field)
          end
        end
      end

      def map_multi_threaded(list, concurrency = 50)
        list.each_slice(concurrency).flat_map do |slice|
          slice
            .map { |data| Thread.new { yield(data) } }
            .each(&:join)
            .map(&:value)
        end
      end

      def parse_field_type(field, line)
        method_name = "parse_field_type_#{field[:type]}"

        if respond_to?(method_name)
          send(method_name, field, line)
        else
          line.strip
        end
      rescue StandardError => e
        AnyQuery::Config.logger.error "Failed to parse field \"#{line}\" with type #{field.inspect}: #{e.message}"
        nil
      end

      def parse_field_type_integer(_, line)
        line.to_i
      end

      def parse_field_type_date(field, line)
        if field[:format]
          Date.strptime(line.strip, field[:format])
        else
          Date.parse(line)
        end
      end

      def parse_field_type_datetime(field, line)
        if field[:format]
          DateTime.strptime(line.strip, field[:format])
        else
          DateTime.parse(line)
        end
      end

      def parse_field_type_float(_, line)
        line.to_f
      end

      def parse_field_type_decimal(_, line)
        BigDecimal(line)
      end

      def parse_field_type_string(_, line)
        line.strip
      end

      def parse_field_type_boolean(_, line)
        line.strip == 'true'
      end

      # @abstract
      class Config
        def initialize(params = {}, &block)
          params.each do |key, value|
            send(key, value) if respond_to?(key)
          end
          instance_eval(&block) if block_given?
        end

        def url(url)
          @url = url
        end

        def primary_key(key)
          @primary_key = key
        end

        def to_h
          {
            url: @url,
            primary_key: @primary_key
          }
        end
      end
    end
  end
end
