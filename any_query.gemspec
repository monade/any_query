# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'any_query/version'

Gem::Specification.new do |s|
  s.name        = 'any_query'
  s.version     = AnyQuery::VERSION
  s.date        = '2023-04-29'
  s.summary     = 'An ORM for any data source (SQL, CSV, TSV, REST API).'
  s.description = 'An ORM for any data source (SQL, CSV, TSV, REST API).'
  s.authors     = ['Mònade']
  s.email       = 'team@monade.io'
  s.files = Dir['lib/**/*']
  s.test_files = Dir['spec/**/*']
  s.required_ruby_version = '>= 3.0.0'
  s.homepage    = 'https://rubygems.org/gems/anyquery'
  s.license     = 'MIT'
  s.add_dependency 'activesupport', ['>= 5', '< 8']
  s.add_dependency 'activemodel', ['>= 5', '< 8']
  s.add_development_dependency 'rspec-rails', '~> 3'
  s.add_development_dependency 'rubocop'
end
