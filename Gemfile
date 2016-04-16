source 'https://rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'

gem 'jbuilder', '2.0.6'
gem 'endpoint_base', github: 'spree/endpoint_base'

gem 'aws-sdk', '~> 1'

group :development do
  gem 'pry'
  gem 'shotgun'
end

group :development, :test do
  gem 'pry-byebug'
end

group :test do
  gem 'vcr'
  gem 'webmock'
  gem 'simplecov'
  gem 'rspec'
  gem 'rack-test'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end

