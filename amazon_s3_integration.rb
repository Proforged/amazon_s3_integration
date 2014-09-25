require_relative 'lib/amazon_s3/amazon_s3'

class AmazonS3Integration < EndpointBase::Sinatra::Base
  set :logging, true

  post '/export_file' do
      result 200, "Done"
  end
end
