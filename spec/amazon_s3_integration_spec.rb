require 'spec_helper'

describe AmazonS3Integration do
  let(:request) do
    {
      request_id: '1234567',
      parameters: {
        access_key_id: aws_testing_credentials[:access_key_id],
        secret_access_key: aws_testing_credentials[:secret_access_key],
        bucket_name: 'bruno-s3-testing',
        file_name: 'shipment',
        folder_name: 'files'
      },
      shipment: sample_shipment
    }
  end

  def json_response
    JSON.parse(last_response.body)
  end

  describe 'POST /export_file' do
    context 'bucket does not exist' do
      it 'returns a message (500)' do
        post '/export_file', request.deep_merge(parameters: { bucket_name: 'not-to-be-found' }).to_json, {}

        expect(json_response["summary"]).to eq "Bucket 'not-to-be-found' was not found."
        expect(last_response.status).to eq 500
      end
    end
  end
end
