require 'spec_helper'

describe AmazonS3Integration do
  let(:request) do
    {
      request_id: '1234567'
    }
  end

  def json_response
    JSON.parse(last_response.body)
  end

  describe 'POST /export_file' do
    it 'works' do
      post '/export_file', request.to_json, {}

      expect(last_response.status).to eq 200
    end
  end
end
