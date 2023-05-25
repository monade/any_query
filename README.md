![Tests](https://github.com/monade/any_query/actions/workflows/test.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/any_query.svg)](https://badge.fury.io/rb/any_query)

# any_query

An ORM for any data source (SQL, CSV, TSV, REST API)

## Installation

Add the gem to your Gemfile

```ruby
  gem 'any_query'
```

### Models

Include `AnyQuery` and create adapters according to your needs:

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

And write the query you need:

```ruby
  Invoice
    .joins(Customer, :customerNumber, %i[customer customerNumber], into: :customer, strategy: :full_scan)
    .select(
      :number, :date, %i[customer name], %i[customer customerNumber], :netAmount
    # :dueDate
    ).to_a
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

About Monade
----------------

![monade](https://monade.io/wp-content/uploads/2021/06/monadelogo.png)

any_query is maintained by [mònade srl](https://monade.io/en/home-en/).

We <3 open source software. [Contact us](https://monade.io/en/contact-us/) for your next project!
