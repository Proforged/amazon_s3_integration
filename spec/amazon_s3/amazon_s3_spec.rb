require 'spec_helper'

describe AmazonS3 do
  subject { described_class.new(s3_client: s3_client, bucket_name: aws_testing[:bucket_name]) }

  describe '#export' do
    context 'when file already exists' do
      it 'saves the csv as original_file_name(nth).csv', :vcr do
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

        expect(
          subject.export(
            file_name: 'already_exists/shipments.csv',
            objects: [sample_shipment, sample_shipment]
          )
        ).to eq "File already_exists/shipments(2).csv was saved to S3"
      end
    end

    context 'when batch' do
      it 'saves the csv with all objects', :vcr do
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
    context 'when file is present' do
      it 'reads the contents of csv as hash', :vcr do
        subject.export(file_name: 'import.csv', objects: [{ id: "R1", status: "shipped" }, { id: "R2", status: "ready" }])
        summary, objects = subject.import(file_name: 'import.csv')

        expect(summary).to eq "File import.csv was read from S3 with 2 object(s)."

        expect(objects[0]["id"]).to eq "R1"
        expect(objects[1]["id"]).to eq "R2"

        expect(objects[0]["status"]).to eq "shipped"
        expect(objects[1]["status"]).to eq "ready"
      end

      it 'removes the file after reading', :vcr do
        subject.export(file_name: 'deleteme.csv', objects: [{ id: 1 }])
        subject.import(file_name: 'deleteme.csv')
        expect {
          subject.import(file_name: 'deleteme.csv')
        }.to raise_error 'File deleteme.csv was not found on S3.'
      end
    end

    context 'when file is not found' do
      it 'raises an exception', :vcr do
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
