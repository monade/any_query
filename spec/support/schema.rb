# frozen_string_literal: true

require 'active_record'

# @example
class ArticleSQL
  include AnyQuery

  adapter :sql do
    url 'sqlite3::memory:'
    primary_key :id
    table 'articles'
  end
end

# @example
class UserSQL
  include AnyQuery

  adapter :sql do
    url 'sqlite3::memory:'
    primary_key :id
    table 'users'
  end
end

# @example
class CommentSQL
  include AnyQuery

  adapter :sql do
    url 'sqlite3::memory:'
    primary_key :id
    table 'comments'
  end
end

class ArticleHTTP
  include AnyQuery

  adapter :http do
    url 'http://example.com'
    primary_key :id
    endpoint :list, :get, "/articles",
    wrapper: [:items],
    pagination: { type: :page },
    default_params: {
      query: { some_query_param: 1 },
      headers: { 'Authorization': 'some' }
    }
    endpoint :show, :get, "/articles/{id}"
  end
end

class UserHTTP
  include AnyQuery

  adapter :http do
    url 'http://example.com'
    primary_key :id
    endpoint :list, :get, "/users",
    wrapper: [:items],
    pagination: { type: :cursor },
    default_params: {
      query: { some_query_param: true },
      headers: { 'Authorization': 'some' }
    }
    endpoint :show, :get, "/users/{id}"
  end
end

class ScopedUserHTTP
  include AnyQuery

  adapter :http do
    url 'http://example.com'
    primary_key :id
    endpoint :list, :get, "/{company_id}/users",
    wrapper: [:items],
    pagination: { type: :none },
    default_params: {
      headers: { 'Authorization': 'some' }
    }
    endpoint :show, :get, "/{company_id}/users/{id}"
  end
end

class ArticleCSV
  include AnyQuery

  adapter :csv do
    url File.join(__dir__, '../fixtures/sample.csv')
    primary_key :id
  end

  field :id, type: :integer
  field :user_id, type: :integer
  field :title, type: :string
  field :body, type: :string
  field :status, type: :integer
  field :created_at, type: :datetime, format: '%Y-%m-%d %H:%M:%S'
end

class ArticleFL
  include AnyQuery

  adapter :fixed_length do
    url File.join(__dir__, '../fixtures/sample.txt')
    primary_key :id
  end

  field :id, type: :integer, length: 4
  field :user_id, type: :integer, length: 4
  field :title, type: :string, length: 30
  field :body, type: :string, length: 100
  field :status, type: :integer, length: 1
  field :created_at, type: :datetime, format: '%Y%m%d%H%M%S', length: 14
end

module Schema
  def self.create
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string   :email
        t.timestamps null: false
      end

      create_table :articles, force: true do |t|
        t.integer  :user_id
        t.string   :title
        t.text     :body
        t.integer   :status
        t.timestamps null: false
      end

      create_table :comments, force: true do |t|
        t.integer  :article_id
        t.text     :body
      end

      ActiveRecord::Base.connection.execute("INSERT INTO users VALUES (1, 'test@test.com', '2021-01-01 00:00:00', '2021-01-01 00:00:00')")
    end
  end
end
