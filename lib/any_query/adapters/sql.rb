# frozen_string_literal: true

module AnyQuery
  module Adapters
    class Sql < Base
      class Config < Base::Config
        def table(name)
          @table = name
        end

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
        ActiveRecord::Base.establish_connection(@config[:url])
        table_name = @config[:table]

        @rails_model = declare_model!
        @rails_model.table_name = table_name
        @rails_model.inheritance_column = :_sti_disabled
        Object.const_set("AnyQuery#{table_name.classify}", @rails_model)
      end

      def declare_model!
        Class.new(ActiveRecord::Base) do
          def dig(key, *other)
            data = public_send(key)
            return data if other.empty?

            return unless data.respond_to?(:dig)

            data.dig(*other)
          end
        end
      end

      attr_reader :rails_model

      def url
        @config[:url]
      end

      def load(_model, select:, joins:, where:, limit:)
        declare_required_associations!(joins)
        chain = @rails_model.all
        chain = chain.where(*where) if where.present?
        chain = chain.limit(limit) if limit.present?
        chain = resolve_joins(chain, joins) if joins.present?

        chain = resolve_select(chain, select) if select.present?

        chain
      end

      def declare_required_associations!(joins)
        joins&.each do |join|
          next if join[:model]._adapter.url != @config[:url]

          relation = join_relation_name(join)

          if join[:as] == :list
            @rails_model.has_many(relation, class_name: join[:model]._adapter.rails_model.to_s,
                                            foreign_key: join[:foreign_key], primary_key: join[:primary_key])
          else
            @rails_model.belongs_to(relation, class_name: join[:model]._adapter.rails_model.to_s,
                                              foreign_key: join[:foreign_key], primary_key: join[:primary_key])
          end
        end
      end

      def resolve_joins(data, joins)
        joins.map do |join|
          if join[:model]._adapter.url == @config[:url]
            relation = join_relation_name(join)

            data = data.eager_load(relation)
          else
            resolve_join(data, join)
          end
        end
        data
      end

      def join_relation_name(join)
        if join[:as] == :list
          join[:model].table_name.pluralize.to_sym
        else
          join[:model].table_name.singularize.to_sym
        end
      end
    end
  end
end
