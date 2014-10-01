require 'spec_helper'

describe AmazonS3 do
  describe "#import" do
    subject { described_class.new(s3_client: s3_client, bucket_name: aws_testing[:bucket_name]) }

    context 'file is not found' do
      it 'raises an exception' do
        expect {
          subject.import(file_name: 'not/to/be-found.csv')
        }.to raise_error "File not/to/be-found.csv was not found on S3."
      end
    end
  end
end

def s3_client
  AWS::S3.new(
    access_key_id: aws_testing[:access_key_id],
    secret_access_key: aws_testing[:secret_access_key],
    region: 'us-east-1' #validate this or else getaddrinfo: nodename nor servname provided, or not known
  )
end
