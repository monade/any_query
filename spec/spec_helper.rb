# frozen_string_literal: true

# require 'rails'
# require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_view/railtie'
# require 'rspec/rails'
# require 'cancancan'
# require 'active_model_serializers'
require 'any_query'
require 'rspec/collection_matchers'
require 'rspec/sql_matcher'
require 'webmock/rspec'

# I18n.enforce_available_locales = false
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Rails.application.config.eager_load = false
# Rails.application.config.active_record.legacy_connection_handling = false

Dir[File.expand_path('support/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    Schema.create
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
