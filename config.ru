require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)
require './amazon_s3_integration'
run AmazonS3Integration