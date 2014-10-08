require 'rubygems'
require 'bundler'
require 'rack/test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', 'amazon_s3_integration.rb')

Dir['./spec/support/**/*.rb'].each &method(:require)

Sinatra::Base.environment = 'test'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.filter_sensitive_data('SECRET_SAUCE') {|_| aws_testing['secret_access_key'] }
  c.filter_sensitive_data('SHHHHHHHHHHH') {|_| aws_testing['access_key_id'] }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around(:each) do |example|
    if example.metadata[:vcr]
      name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")

      VCR.use_cassette(name, {}, &example)
    else
      example.run
    end
  end
end

def app
  AmazonS3Integration
end
