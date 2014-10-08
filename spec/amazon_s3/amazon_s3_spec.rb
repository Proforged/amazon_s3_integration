require 'spec_helper'

describe AmazonS3 do
  subject { described_class.new(s3_client: s3_client, bucket_name: aws_testing[:bucket_name]) }

  describe '#export' do
    context 'unknown file_type', :vcr do
      it 'raises an error' do
        expect {
          subject.export(file_name: 'a.xpto', file_type: 'xpto', objects: [{}])
        }.to raise_error "Please use a valid file type: csv or json. Received: xpto."
      end
    end

    context 'when file already exists' do
      it 'saves the csv as original_file_name(nth).csv', :vcr do
        subject.export(
          file_name: 'already_exists/shipments.csv',
          file_type: 'csv',
          objects: [sample_shipment, sample_shipment]
        )

        expect(
          subject.export(
            file_name: 'already_exists/shipments.csv',
            file_type: 'csv',
            objects: [sample_shipment, sample_shipment]
          )
        ).to eq "File already_exists/shipments(1).csv was saved to S3"

        expect(
          subject.export(
            file_name: 'already_exists/shipments.csv',
            file_type: 'csv',
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
            file_type: 'csv',
            objects: [sample_shipment, sample_shipment]
          )
        ).to eq "File batch/shipments.csv was saved to S3"
      end
    end
  end

  describe '#import' do
    context 'unknown file_type', :vcr do
      it 'raises an error' do
        expect {
          subject.import(file_name: 'a.xpto', file_type: 'xpto')
        }.to raise_error "Please use a valid file type: csv or json. Received: xpto."
      end
    end

    context 'when file is present' do
      it 'reads the contents of csv as hash', :vcr do
        subject.export(file_name: 'import.csv', file_type: 'csv', objects: [{ id: "R1", status: "shipped" }, { id: "R2", status: "ready" }])
        summary, objects = subject.import(file_name: 'import.csv', file_type: 'csv')

        expect(summary).to eq "File import.csv was read from S3 with 2 object(s)."

        expect(objects[0]["id"]).to eq "R1"
        expect(objects[1]["id"]).to eq "R2"

        expect(objects[0]["status"]).to eq "shipped"
        expect(objects[1]["status"]).to eq "ready"
      end

      it 'removes the file after reading', :vcr do
        subject.export(file_name: 'deleteme.csv', file_type: 'csv', objects: [{ id: 1 }])
        subject.import(file_name: 'deleteme.csv', file_type: 'csv')

        summary, objects = subject.import(file_name: 'deleteme.csv', file_type: 'csv')
        expect(summary).to be_nil
        expect(objects).to eq []
      end
    end

    context 'when file is not found' do
      it 'return nil summary, no objects', :vcr do
        summary, objects = subject.import(file_name: 'not/to/be-found.csv', file_type: 'csv')
        expect(summary).to be_nil
        expect(objects).to eq []
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
