# frozen_string_literal: true

require 'spec_helper'

describe ArticleSQL do
  before do
    ActiveRecord::Base.connection.execute('INSERT INTO articles VALUES (1, 1, "Title 1", "Body 1", 1, "2021-01-01 00:00:00", "2021-01-01 00:00:00")')
    ActiveRecord::Base.connection.execute('INSERT INTO articles VALUES (2, 1, "Title 2", "Body 2", 2, "2021-01-01 00:00:00", "2021-01-01 00:00:00")')
  end

  it 'returns records' do
    expect(described_class.all.to_a).to have(2).items
  end

  it 'can be finded' do
    result = described_class.find(2)
    expect(result.id).to eq(2)
    expect(result.user_id).to eq(1)
    expect(result.title).to eq('Title 2')
    expect(result.body).to eq('Body 2')
    expect(result.status).to eq(2)
    expect(result.created_at).to eq('2021-01-01 00:00:00 UTC'.to_datetime)
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
    end.to match_query(/ LEFT OUTER JOIN "users"/)
  end

  it 'can be joined on many' do
    ActiveRecord::Base.connection.execute('INSERT INTO comments VALUES (1, 1, "content")')
    ActiveRecord::Base.connection.execute('INSERT INTO comments VALUES (2, 1, "content2")')

    expect do
      result = described_class.joins(CommentSQL, :id, :article_id, into: :comments, as: :list).to_a.first
      expect(result.comments).to have(2).items
    end.to match_query(/ LEFT OUTER JOIN "comments" ON "comments"/)
  end

  it 'can be selected with nested selectors' do
    results = described_class
              .joins(UserSQL, :id, :user_id, into: :user, as: :single)
              .select(:id, :title, %i[user email])
              .to_a

    expect(results).to have(2).items
    expect(results[0]).to have(3).items
  end
end
