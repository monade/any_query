![Tests](https://github.com/monade/any_query/actions/workflows/test.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/any_query.svg)](https://badge.fury.io/rb/any_query)

# any_query

`any_query` is a versatile ORM designed to interface with various data sources including SQL, CSV, TSV, Fixed Length Text Format, and REST APIs. With any_query, you can write SQL-like queries and receive results as ActiveRecord-like objects. It supports operations like `select`, `limit`, and even `joins` across different data sources.

## Features
* Unified Query Language: Write SQL-like queries for any supported data source.
* ActiveRecord-like Objects: Get results in a familiar format.
* Cross-data Source Joins: Combine data from different sources seamlessly.

## Installation

To install `any_query`, add the gem to your Gemfile:

```ruby
  gem 'any_query'
```

Then run:

```bash
  bundle install
```

## Usage
### Setting up Models
To use `any_query`, include it in your model and set up the necessary adapters:


```ruby
class Invoice
  include AnyQuery

  adapter :http do
    url 'https://your-api.dev'
    primary_key :id
    endpoint :list, :get, '/v2/invoices',
             pagination: { type: :page, params: { per: 'pageSize', number: 'skippages' } },
             wrapper: :collection,
             default_params: {
               query: { pageSize: 1000 },
               headers: {
                 'Content-Type': 'application/json'
               }
             }
    endpoint :show, :get, '/v2/invoices{id}',
             default_params: {
               headers: {
                 'Content-Type': 'application/json'
               }
             }
  end
end

class Customer
  include AnyQuery

  adapter :http do
    url 'https://your-api.dev'
    primary_key :id
    endpoint :list, :get, '/customers/',
             pagination: { type: :page, params: { per: 'pageSize', cursor: 'cursor', number: 'skippages' } },
             wrapper: :collection,
             default_params: {
               query: { pageSize: 1000 },
               headers: {
                 'Content-Type': 'application/json'
               }
             }
    endpoint :show, :get, '/customers/{id}',
             default_params: {
               headers: {
                 'Content-Type': 'application/json'
               }
             }
  end
end
```

### Writing Queries
With your models set up, you can now write queries:

```ruby
  Invoice
    .joins(Customer, :customerNumber, %i[customer customerNumber], into: :customer, strategy: :full_scan)
    .select(
      :number, :date, %i[customer name], %i[customer customerNumber], :netAmount
    # :dueDate
    ).to_a
```

### Standalone Mode
You can also use `any_query` without models by creating a client directly:

```ruby
  sql_client = AnyQuery::Client.new(
    adapter: :sql,
    params: {
      url: 'psql://user:password@localhost:5432/dbname',
      primary_key: :id,
      table: 'users'
    }
  )

  csv_client = AnyQuery::Client.new(
    adapter: :csv,
    params: {
      url: 'path/to/file.csv',
      primary_key: :id,
      fields: {
        id: { type: :integer },
        user_id: { type: :integer },
        title: { type: :string },
        body: { type: :string },
        status: { type: :integer },
        created_at: { type: :datetime, format: '%Y-%m-%d %H:%M:%S' }
      }
    }
  )

  # Querying
  csv_client
    .joins(sql_client, :user_id, :id, into: :user, strategy: :full_scan)
    .select(:number, :date, :customerNumber, :netAmount)
    .to_a
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

About Monade
----------------

![monade](https://monade.io/wp-content/uploads/2021/06/monadelogo.png)

any_query is maintained by [mònade srl](https://monade.io/en/home-en/).

We <3 open source software. [Contact us](https://monade.io/en/contact-us/) for your next project!
