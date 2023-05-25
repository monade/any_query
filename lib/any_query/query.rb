# frozen_string_literal: true

module AnyQuery
  # @api private
  class Query
    include Enumerable

    delegate_missing_to :to_a

    def initialize(model, adapter)
      @model = model
      @adapter = adapter
    end

    def joins(model, primary_key, foreign_key, into:, as: :single, strategy: :default)
      dup.joins!(model, primary_key, foreign_key, into:, as:, strategy:)
    end

    def with_single
      dup.joins!(:show, :id, :id, into: :single, as: :single, strategy: :single)
    end

    def where(options)
      dup.where!(options)
    end

    def select(*args)
      dup.select!(*args)
    end

    def limit(limit)
      dup.limit!(limit)
    end

    def find(id)
      @adapter.load_single(@model, id, [])
    end

    def to_a
      @adapter.load(@model, select: @select, joins: @joins, where: @where, limit: @limit)
    end

    def each(&block)
      to_a.each(&block)
    end

    def joins!(model, primary_key, foreign_key, into:, as: :single, strategy: :default)
      @joins ||= []
      @joins << ({ model:, primary_key:, foreign_key:, into:, as:, strategy: })
      self
    end

    def select!(*args)
      @select ||= []
      @select += args
      self
    end

    def where!(options)
      @where ||= []
      @where << options
      self
    end

    def limit!(limit)
      @limit = limit
      self
    end
  end
end
