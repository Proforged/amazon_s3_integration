require 'spec_helper'

describe AmazonS3Integration do

  def json_response
    JSON.parse(last_response.body)
  end

  let(:common_request) do
    {
      request_id: '1234567',
      parameters: {
        access_key_id: aws_testing[:access_key_id],
        secret_access_key: aws_testing[:secret_access_key],
        region: 'us-east-1',
        bucket_name: aws_testing[:bucket_name],
      }
    }
  end

  describe 'POST /export_file' do
    context 'when file type is csv' do
      it 'saves to S3 and returns a summary (200)', :vcr do
        post '/export_file', common_request.deep_merge({
          parameters: {
            file_name: 'files/shipment.csv'
          },
          shipment: sample_shipment("R9")
        }).to_json, {}

        expect(json_response["summary"]).to eq "File files/shipment.csv was saved to S3"
        expect(last_response.status).to eq 200
      end
    end

    context 'when file type is json' do
      it 'saves to S3 and returns a summary (200)', :vcr do
        post '/export_file', common_request.deep_merge({
          parameters: {
            file_name: 'json/shipment.json'
          },
          shipment: sample_shipment("R9")
        }).to_json, {}

        expect(json_response["summary"]).to eq "File json/shipment.json was saved to S3"
        expect(last_response.status).to eq 200
      end
    end

    context 'bucket does not exist' do
      it 'returns a message (500)', :vcr do
        post '/export_file', common_request.deep_merge(parameters: { bucket_name: 'not-to-be-found' }).to_json, {}

        expect(json_response["summary"]).to eq "Bucket 'not-to-be-found' was not found."
        expect(last_response.status).to eq 500
      end
    end

    context 'when batch request' do
      let(:request) do
        {
          parameters: {
            file_name: 'files/shipment_batch.csv'
          },
          shipments: [sample_shipment("R9"), sample_shipment("R1")]
        }.deep_merge(common_request)
      end

      it 'saves to S3 and returns a summary (200)', :vcr do
        post '/export_file', request.to_json, {}

        expect(json_response["summary"]).to eq "File files/shipment_batch.csv was saved to S3"
        expect(last_response.status).to eq 200
      end
    end
  end

  describe 'POST /import_file' do
    let(:request) do
      {
        parameters: {
          file_name: 'files/shipment_batch.csv',
          object_type: 'shipment'
        }
      }.deep_merge(common_request)
    end

    it 'reads from S3 and returns object and summary (200)', :vcr do
      post '/import_file', request.to_json, {}

      expect(json_response["summary"]).to eq "File files/shipment_batch.csv was read from S3 with 2 object(s)."
      expect(json_response["shipments"][0]["id"]).to eq "R9"

      expect(last_response.status).to eq 200
    end

    context 'when json' do
      it 'reads from S3 and returns object and summary (200)', :vcr do
        post '/import_file', request.deep_merge({
          parameters: {
            file_name: 'json/shipment.json'
            }
          }).to_json, {}

        expect(json_response["summary"]).to eq "File json/shipment.json was read from S3 with 1 object(s)."
        expect(json_response["shipments"][0]["id"]).to eq "R9"

        expect(last_response.status).to eq 200
      end
    end

    context 'wrong aws region' do
      it 'warns the user in the summary' do
        expect(AmazonS3).to receive(:new).and_raise SocketError

        post '/import_file', request.deep_merge(parameters: { region: 'cucamonga-1' }).to_json, {}

        expect(json_response["summary"]).to eq "Unable to reach Amazon S3. Please make sure 'cucamonga-1' is a valid region"
        expect(last_response.status).to eq 500
      end
    end
  end
end
