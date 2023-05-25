# frozen_string_literal: true

require 'spec_helper'

describe ArticleHTTP do
  before do
    stub_request(:get, 'http://example.com/articles?page=0&some_query_param=1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          {
            items: [
              {
                id: 1,
                user_id: 1,
                name: 'some article'
              },
              {
                id: 2,
                user_id: 1,
                name: 'some article 2'
              }
            ]
          }
        )
      )

    stub_request(:get, 'http://example.com/articles?page=1&some_query_param=1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: '{ "items": [] }'
      )
  end

  it 'returns records' do
    expect(described_class.all.to_a).to have(2).items
  end

  it 'can be finded' do
    stub_request(:get, 'http://example.com/articles/1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          {
            id: 1,
            user_id: 1,
            title: 'some article'
          }
        )
      )
    result = described_class.find(1)
    expect(result.id).to eq(1)
    expect(result.user_id).to eq(1)
    expect(result.title).to eq('some article')
  end

  it 'can be filtered' do
    stub_request(:get, 'http://example.com/articles?page=0&some_query_param=1&status=1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          {
            items: [
              {
                id: 1,
                name: 'some article'
              }
            ]
          }
        )
      )
    stub_request(:get, 'http://example.com/articles?page=1&some_query_param=1&status=1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: '{ "items": [] }'
      )

    expect(described_class.where(status: 1).to_a).to have(1).items
  end

  it 'can be limited' do
    expect(described_class.limit(1).to_a).to have(1).items
  end

  it 'can be joined with SQL' do
    described_class.joins(UserSQL, :id, :user_id, into: :user).to_a.first
  end

  it 'can be joined with itself using the show endpoint' do
    stub_request(:get, 'http://example.com/articles/1')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          {
            id: 1,
            user_id: 1,
            title: 'some article',
            some_additional_field: 'some value'
          }
        )
      )

    stub_request(:get, 'http://example.com/articles/2')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          {
            id: 2,
            user_id: 1,
            title: 'some article 2',
            some_additional_field: 'some value'
          }
        )
      )

    result = described_class.with_single.to_a.first
    expect(result.some_additional_field).to eq('some value')
  end

  it 'can be joined with HTTP(s)' do
    stub_request(:get, 'http://example.com/users?id%5B%5D=1&some_query_param=true')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          items: [
            { "id": 1, "email": 'gianni@gianni.com' }
          ],
          cursor: '123123123'
        )
      )

    stub_request(:get, 'http://example.com/users?id%5B%5D=1&some_query_param=true&cursor=123123123')
      .to_return(
        headers: { content_type: 'application/json' },
        body: JSON.dump(
          items: [],
          cursor: '123123123'
        )
      )

    result = described_class.joins(UserHTTP, :id, :user_id, into: :user).to_a.first
    expect(result.user.email).to eq('gianni@gianni.com')
  end

  it 'can be selected with nested selectors' do
    results = described_class
              .joins(UserSQL, :id, :user_id, into: :user, as: :single)
              .select(:id, :title, %i[user email])
              .to_a

    expect(results).to have(2).items
    expect(results[0]).to have(3).items
  end

  context 'with url params' do
    it 'can be filtered using query params' do
      stub_request(:get, 'http://example.com/1/users')
      ScopedUserHTTP.where(company_id: 1).to_a
    end
  end
end
