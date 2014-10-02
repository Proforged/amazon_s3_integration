require 'spec_helper'

describe AmazonS3 do
  subject { described_class.new(s3_client: s3_client, bucket_name: aws_testing[:bucket_name]) }

  describe '#export' do
    context 'when file already exists' do
      it 'saves the csv as original_file_name(nth).csv' do
        subject.export(
          file_name: 'already_exists/shipments.csv',
          objects: [sample_shipment, sample_shipment]
        )

        expect(
          subject.export(
            file_name: 'already_exists/shipments.csv',
            objects: [sample_shipment, sample_shipment]
          )
        ).to eq "File already_exists/shipments(1).csv was saved to S3"
      end
    end

    context 'when batch' do
      it 'saves the csv with all objects' do
        expect(
          subject.export(
            file_name: 'batch/shipments.csv',
            objects: [sample_shipment, sample_shipment]
          )
        ).to eq "File batch/shipments.csv was saved to S3"
      end
    end
  end

  describe '#import' do
    context 'file is not found' do
      it 'raises an exception' do
        expect {
          subject.import(file_name: 'not/to/be-found.csv')
        }.to raise_error 'File not/to/be-found.csv was not found on S3.'
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
