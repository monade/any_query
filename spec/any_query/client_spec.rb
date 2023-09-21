# frozen_string_literal: true

require 'spec_helper'

describe AnyQuery::Client do
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

  context 'with sql' do
    subject do
      described_class.new(
        adapter: :sql,
        params: {
          url: 'sqlite3::memory:',
          primary_key: :id,
          table: 'users'
        }
      )
    end

    let(:fixed_length_client) do
      described_class.new(
        adapter: :fixed_length,
        params: {
          url: File.join(__dir__, '../fixtures/sample.txt'),
          primary_key: :id,
          fields: {
            id: { type: :integer, length: 4 },
            user_id: { type: :integer, length: 4 },
            title: { type: :string, length: 30 },
            body: { type: :string, length: 100 },
            status: { type: :integer, length: 1 },
            created_at: { type: :datetime, format: '%Y%m%d%H%M%S', length: 14 }
          }
        }
      )
    end

    it 'returns records' do
      subject
      # Re-create schema since it's a new connection
      Schema.create
      result = subject.all.to_a
      expect(result).to have(1).items
      expect(result[0].email).to eq('test@test.com')

      joined_result = fixed_length_client.joins(subject, :id, :user_id, into: :user).to_a

      expect([joined_result.first.user_id, joined_result.first.user.email]).to eq([1, 'test@test.com'])
    end
  end

  context 'with http' do
    subject do
      described_class.new(
        adapter: :http,
        params: {
          url: 'http://example.com',
          primary_key: :id,
          endpoints: [
            {
              scope: :list,
              method: :get,
              path: '/articles',
              wrapper: [:items],
              pagination: { type: :page },
              default_params: {
                query: { some_query_param: 1 },
                headers: { 'Authorization': 'some' }
              }
            },
            {
              scope: :show,
              method: :get,
              path: '/articles/{id}'
            }
          ]
        }
      )
    end

    it 'returns records' do
      expect(subject.all.to_a).to have(2).items
    end
  end

  context 'with csv' do
    subject do
      described_class.new(
        adapter: :csv,
        params: {
          url: File.join(__dir__, '../fixtures/sample.csv'),
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
    end
    let(:result) { subject.all.to_a }

    it 'returns records' do
      expect(result).to have(2).items
    end
  end

  context 'with fixed length exports' do
    subject do
      described_class.new(
        adapter: :fixed_length,
        params: {
          url: File.join(__dir__, '../fixtures/sample.txt'),
          primary_key: :id,
          fields: {
            id: { type: :integer, length: 4 },
            user_id: { type: :integer, length: 4 },
            title: { type: :string, length: 30 },
            body: { type: :string, length: 100 },
            status: { type: :integer, length: 1 },
            created_at: { type: :datetime, format: '%Y%m%d%H%M%S', length: 14 }
          }
        }
      )
    end

    let(:result) { subject.all.to_a }

    it 'returns records' do
      expect(result).to have(2).items

      expect(result[1].id).to eq(2)
      expect(result[1].user_id).to eq(1)
      expect(result[1].title).to eq('this is another sample')
      expect(result[1].body).to eq('this is an example of a body for an article that is very long and dirty')
      expect(result[1].status).to eq(2)
      expect(result[1].created_at).to eq('2023-12-31T19:00:00Z'.to_datetime)
    end
  end
end
