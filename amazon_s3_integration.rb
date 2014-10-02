require_relative 'lib/amazon_s3/amazon_s3'

require 'active_support/inflector'
class AmazonS3Integration < EndpointBase::Sinatra::Base
  set :logging, true

  error SocketError do
    result 500, "Unable to reach Amazon S3. Please make sure '#{@config[:region]}' is a valid region"
  end

  post '/export_file' do
    summary = AmazonS3.new(
      s3_client:    s3_client,
      bucket_name:  @config[:bucket_name],
    ).export(
      file_name:    @config[:file_name],
      objects:      objects
    )

    if batch?
      add_value "success", { summary => objects.collect {|o| o["id"]} }
    end

    result 200, summary
  end

  post '/import_file' do
    summary, objects = AmazonS3.new(
      s3_client:    s3_client,
      bucket_name:  @config[:bucket_name],
    ).import(
      file_name:    @config[:file_name]
    )

    objects.each do |object|
      add_object @config[:object_type], object
    end if objects

    result 200, summary
  end

  def s3_client
    AWS::S3.new(
      access_key_id: @config[:access_key_id],
      secret_access_key: @config[:secret_access_key],
      region: @config[:region].to_s.downcase
    )
  end

  def objects
    Array.wrap(@payload.except(:parameters, :request_id).values.first)
  end

  def batch?
    objects.size > 1
  end
end
