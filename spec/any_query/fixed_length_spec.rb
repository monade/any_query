# frozen_string_literal: true

require 'spec_helper'

describe ArticleFL do
  it 'returns records' do
    expect(described_class.all.to_a).to have(2).items
  end

  it 'can be finded' do
    result = described_class.find(2)
    expect(result.id).to eq(2)
    expect(result.user_id).to eq(1)
    expect(result.title).to eq('this is another sample')
    expect(result.body).to eq('this is an example of a body for an article that is very long and dirty')
    expect(result.status).to eq(2)
    expect(result.created_at).to eq('2023-12-31T19:00:00Z'.to_datetime)
  end

  it 'can be filtered' do
    expect(described_class.where(status: 1).to_a).to have(1).items
  end

  it 'can be limited' do
    expect(described_class.limit(1).to_a).to have(1).items
  end

  it 'can be joined' do
    expect do
      described_class.joins(UserSQL, :id, :user_id, into: :user).to_a.first
    end.to match_query(/SELECT "users".* FROM "users"/)
  end

  it 'can be selected with nested selectors' do
    results = described_class
              .joins(UserSQL, :id, :user_id, into: :user, as: :single)
              .select(:id, :title, %i[user email])
              .to_a

    expect(results).to eq(
      [
        [1, 'this is a sample', 'test@test.com'],
        [2, 'this is another sample', 'test@test.com']
      ]
    )
  end
end
