# frozen_string_literal: true

module AnyQuery
  module Adapters
    # @api private
    class Http < Base
      MAX_ITERATIONS = 1000
      # @api private
      class Config < Base::Config
        def initialize(params = {}, &block)
          super
          params[:endpoints]&.each do |endpoint_params|
            endpoint(endpoint_params[:scope], endpoint_params[:method], endpoint_params[:path], endpoint_params)
          end
        end

        def endpoint(name, method, path, options = {})
          @endpoints ||= {}
          @endpoints[name] = { method:, path:, options: }
        end

        def to_h
          {
            url: @url,
            primary_key: @primary_key,
            wrapper: @wrapper,
            endpoints: @endpoints
          }
        end
      end

      def load(model, select:, joins:, where:, limit:)
        data = run_http_list_query(where)

        data = resolve_joins(data, joins) if joins.present?
        data = data.first(limit) if limit.present?

        parse_response(model, select, data)
      end

      def load_single(model, id, joins)
        data = run_http_single_query(id, {})

        data = resolve_joins(data, joins) if joins.present?

        instantiate_model(model, data)
      end

      def parse_response(model, select, data)
        data = data.map do |record|
          instantiate_model(model, record)
        end
        data = resolve_select(data, select) if select.present?

        data
      end

      # FIXME: Use common method
      def load_single_from_list(result_list)
        result_list.each_slice(50).flat_map do |slice|
          slice
            .map { |data| Thread.new { run_http_single_query(data[:id], {}) } }
            .each(&:join)
            .map(&:value)
        end
      end

      def resolve_joins(data, joins)
        data = load_single_from_list(data) if joins.any? { |j| j[:model] == :show }

        joins.each do |join|
          next if join[:model] == :show

          resolve_join(data, join)
        end
        data
      end

      def build_filters(where)
        {
          query: (where || {}).inject({}) do |memo, object|
                   memo.merge(object)
                 end
        }
      end

      def run_http_single_query(id, params)
        endpoint = @config[:endpoints][:show]
        url = build_url(endpoint, params, id:)
        params = (endpoint[:options][:default_params] || {}).merge(params)
        AnyQuery::Config.logger.debug "Starting request to #{url} with params #{params.inspect}"

        data = run_http_request(endpoint, url, params)
        data = data.dig(*endpoint[:options][:wrapper]) if endpoint[:options][:wrapper]
        AnyQuery::Config.logger.debug 'Responded with single record.'
        data
      end

      def run_http_list_query(raw_params)
        endpoint = @config[:endpoints][:list]
        url = build_url(endpoint, raw_params)
        params = build_filters(raw_params)
        results = Set.new
        previous_response = nil
        MAX_ITERATIONS.times do |i|
          params = merge_params(endpoint, params, i, previous_response)

          AnyQuery::Config.logger.debug "Starting request to #{url} with params #{params.inspect}"

          data = run_http_request(endpoint, url, params)
          break if previous_response == data

          previous_response = data

          data = unwrap(endpoint, data)

          AnyQuery::Config.logger.debug "Responded with #{data&.size || 0} records"
          break if !data || data.empty?

          previous_count = results.size
          results += data
          break if results.size == previous_count

          break if endpoint.dig(:options, :pagination, :type) == :none
        end
        results.to_a
      end

      def merge_params(endpoint, params, iteration, previous_response)
        (endpoint.dig(:options, :default_params) || {})
          .deep_merge(params)
          .deep_merge(handle_pagination(endpoint, iteration, previous_response))
      end

      def build_url(endpoint, params, id: nil)
        output = (@config[:url] + endpoint[:path])

        output.gsub!('{id}', id.to_s) if id

        if output.include?('{')
          output.gsub!(/\{([^}]+)\}/) do |match|
            key = Regexp.last_match(1).to_sym
            hash = params.find { |h| h[Regexp.last_match(1).to_sym] }
            hash&.delete(key) || match
          end
        end

        output
      end

      def unwrap(endpoint, data)
        data = unwrap_list(endpoint, data)
        unwrap_single(endpoint, data)
      end

      def unwrap_list(endpoint, data)
        wrapper = endpoint.dig(:options, :wrapper)
        return data unless wrapper

        if wrapper.is_a?(Proc)
          wrapper.call(data)
        else
          data.dig(*wrapper)
        end
      end

      def unwrap_single(endpoint, data)
        return data unless endpoint.dig(:options, :single_wrapper)

        data.map! do |row|
          row.dig(*endpoint[:options][:single_wrapper])
        end
      end

      def run_http_request(endpoint, url, params)
        response = HTTParty.public_send(endpoint[:method], url, params)

        raise response.inspect unless response.success?

        symbolize_keys(response.parsed_response)
      end

      def symbolize_keys(response)
        if response.is_a?(Array)
          response.map do |item|
            symbolize_keys(item)
          end
        else
          response.respond_to?(:deep_symbolize_keys) ? response&.deep_symbolize_keys : response
        end
      end

      def handle_pagination(endpoint, index, previous_response = nil)
        pagination = endpoint.dig(:options, :pagination) || {}
        method_name = "handle_pagination_#{pagination[:type]}"
        if respond_to?(method_name, true)
          send(method_name, pagination, index, previous_response)
        else
          AnyQuery::Config.logger.warn "Unknown pagination type #{pagination[:type]}"
          { query: { page: index } }
        end
      end

      def handle_pagination_page(pagination, index, _previous_response)
        starts_from = pagination[:starts_from] || 0
        { query: { (pagination.dig(:params, :number) || :page) => starts_from + index } }
      end

      def handle_pagination_skip(_pagination, _index, _previous_response)
        raise 'TODO: Implement skip pagination'
      end

      def handle_pagination_cursor(pagination, _index, previous_response)
        return {} unless previous_response

        cursor_parameter = pagination.dig(:params, :cursor) || :cursor
        cursor = previous_response[cursor_parameter]
        { query: { (pagination.dig(:params, :cursor) || :cursor) => cursor } }
      end

      def handle_pagination_none(_pagination, _index, _previous_response)
        {}
      end
    end
  end
end
