require_relative 'lib/amazon_s3/amazon_s3'

class AmazonS3Integration < EndpointBase::Sinatra::Base
  set :logging, true

  post '/export_file' do
    success, summary = AmazonS3.new(
      s3_client:    s3_client,
      bucket_name:  @config[:bucket_name],
    ).export(
      file_name:    @config[:file_name],
      folder_name:  @config[:folder_name],
      object:       @payload[:shipment]
    )

    result success_to_code(success), summary
  end

  post '/import_file' do
    success, summary, object = AmazonS3.new(
      s3_client:    s3_client,
      bucket_name:  @config[:bucket_name],
    ).import(
      file_name:    @config[:file_name],
      folder_name:  @config[:folder_name],
      object_type:  @config[:object_type]
    )

    add_object object.keys[0], object.values[0] # check if object, iterate if > 1

    result success_to_code(success), summary
  end

  def s3_client
    AWS::S3.new(
      access_key_id: @config[:access_key_id],
      secret_access_key: @config[:secret_access_key],
      region: 'us-east-1' #validate this or else getaddrinfo: nodename nor servname provided, or not known
    )
  end

  def success_to_code(bool)
    bool ? 200 : 500
  end
end
