require 'spec_helper'

describe Converter do
  subject { described_class }

  let(:worst_case_json) do
      {
        id: "R154085346541340",
        string: "USD",
        hash_nested: {
          adjustment: "20",
          tax: "10",
          shipping: {
            airplane: "5",
            land: {
              north: "1",
              south: "2"
            }
          }
        },
        array_of_hashes: [{
          id: "1",
          status: "shipped"
        }, {
          id: "2",
          status: "ready"
        }],
        array: ["red", "green", "refactor"],
        array_with_hash: ["10", { a: "1", b: "2" }],
        array_with_nested_array: ["yes", ["no", "nope"], [[["maybe"]]]]
      }
  end

  describe '.csv_header' do
    it 'generates a header by flattening the json' do
      expect(subject.csv_header(worst_case_json)).to eq([
        "id", "string", "hash_nested.adjustment", "hash_nested.tax", "hash_nested.shipping.airplane", "hash_nested.shipping.land.north", "hash_nested.shipping.land.south", "array_of_hashes.0.id", "array_of_hashes.0.status", "array_of_hashes.1.id", "array_of_hashes.1.status", "array.0", "array.1", "array.2", "array_with_hash.0", "array_with_hash.1.a", "array_with_hash.1.b", "array_with_nested_array.0", "array_with_nested_array.1.0", "array_with_nested_array.1.1", "array_with_nested_array.2.0.0.0"
      ])
    end
  end

  describe '.json_path' do
    tests = {
      "id"                              => "R154085346541340",
      "string"                          => "USD",
      "hash_nested.adjustment"          => "20",
      "hash_nested.tax"                 => "10",
      "hash_nested.shipping.airplane"   => "5",
      "hash_nested.shipping.land.north" => "1",
      "hash_nested.shipping.land.south" => "2",
      "array_of_hashes.0.id"            => "1", # { array_of_hashes: [{ id: 1 }] }
      "array_of_hashes.0.status"        => "shipped", # { array_of_hashes: [{ id:1, status: "shipped"}]
      "array_of_hashes.1.id"            => "2",
      "array_of_hashes.1.status"        => "ready",
      "array.0"                         => "red",
      "array.1"                         => "green",
      "array.2"                         => "refactor",
      "array_with_hash.0"               => "10",
      "array_with_hash.1.a"             => "1",
      "array_with_hash.1.b"             => "2",
      "array_with_nested_array.0"       => "yes",
      "array_with_nested_array.1.0"     => "no",
      "array_with_nested_array.1.1"     => "nope",
      "array_with_nested_array.2.0.0.0" => "maybe"
    }

    tests.each do |path, value|
      it "navigates through the path #{path}" do
        expect(subject.json_path(worst_case_json, path)).to eq value
      end
    end

    context 'value not found for path' do
      tests = [
        "nothing",
        "nothing.really.nada",
        "hash_nested.shipping.0.north",
        "array_of_hashes.0.id.0.1",
        "0.0.0.0"
      ]

      tests.each do |path|
        it "returns \"\" for #{path}" do
          expect(subject.json_path(worst_case_json, path)).to eq ""
        end
      end
    end
  end

  describe '.array_of_hashes_to_csv' do
    it 'transforms multiple hashes into csv' do
      expect(subject.array_of_hashes_to_csv([worst_case_json, worst_case_json])).to eq "id,string,hash_nested.adjustment,hash_nested.tax,hash_nested.shipping.airplane,hash_nested.shipping.land.north,hash_nested.shipping.land.south,array_of_hashes.0.id,array_of_hashes.0.status,array_of_hashes.1.id,array_of_hashes.1.status,array.0,array.1,array.2,array_with_hash.0,array_with_hash.1.a,array_with_hash.1.b,array_with_nested_array.0,array_with_nested_array.1.0,array_with_nested_array.1.1,array_with_nested_array.2.0.0.0\nR154085346541340,USD,20,10,5,1,2,1,shipped,2,ready,red,green,refactor,10,1,2,yes,no,nope,maybe\nR154085346541340,USD,20,10,5,1,2,1,shipped,2,ready,red,green,refactor,10,1,2,yes,no,nope,maybe"
    end
  end

  describe '.hash_to_csv' do
    let(:csv_fixture) do
      "id,string,hash_nested.adjustment,hash_nested.tax,hash_nested.shipping.airplane,hash_nested.shipping.land.north,hash_nested.shipping.land.south,array_of_hashes.0.id,array_of_hashes.0.status,array_of_hashes.1.id,array_of_hashes.1.status,array.0,array.1,array.2,array_with_hash.0,array_with_hash.1.a,array_with_hash.1.b,array_with_nested_array.0,array_with_nested_array.1.0,array_with_nested_array.1.1,array_with_nested_array.2.0.0.0\nR154085346541340,USD,20,10,5,1,2,1,shipped,2,ready,red,green,refactor,10,1,2,yes,no,nope,maybe"
    end

    it 'transforms json into a flat csv' do
      expect(subject.hash_to_csv(worst_case_json)).to eq csv_fixture
    end
  end

  describe '.csv_to_hash' do
    let(:csv_fixture) do
      "id,string,hash_nested.adjustment,hash_nested.tax,hash_nested.shipping.airplane,hash_nested.shipping.land.north,hash_nested.shipping.land.south,array_of_hashes.0.id,array_of_hashes.0.status,array_of_hashes.1.id,array_of_hashes.1.status,array.0,array.1,array.2,array_with_hash.0,array_with_hash.1.a,array_with_hash.1.b,array_with_nested_array.0,array_with_nested_array.1.0,array_with_nested_array.1.1,array_with_nested_array.2.0.0.0\nR154085346541340,USD,20,10,5,1,2,1,shipped,2,ready,red,green,refactor,10,1,2,yes,no,nope,maybe"
    end

    it 'returns the object' do
      expect(subject.csv_to_hash(csv_fixture)[0].with_indifferent_access).to eq worst_case_json.with_indifferent_access
    end

    context 'when csv has multiple lines' do
      let(:csv_fixture) do
        "id,string,hash_nested.adjustment,hash_nested.tax,hash_nested.shipping.airplane,hash_nested.shipping.land.north,hash_nested.shipping.land.south,array_of_hashes.0.id,array_of_hashes.0.status,array_of_hashes.1.id,array_of_hashes.1.status,array.0,array.1,array.2,array_with_hash.0,array_with_hash.1.a,array_with_hash.1.b,array_with_nested_array.0,array_with_nested_array.1.0,array_with_nested_array.1.1,array_with_nested_array.2.0.0.0\nR154085346541340,USD,20,10,5,1,2,1,shipped,2,ready,red,green,refactor,10,1,2,yes,no,nope,maybe\nR123,BRL,20,10,5,1,2,1,shipped,2,ready,red,red,omg,10,1,2,yes,no,nope,maybe"
      end

      it 'returns an array of objects' do
        expect(subject.csv_to_hash(csv_fixture)[0]["id"]).to eq "R154085346541340"
        expect(subject.csv_to_hash(csv_fixture)[1]["id"]).to eq "R123"

        expect(subject.csv_to_hash(csv_fixture)[0]["array"]).to eq ["red", "green", "refactor"]
        expect(subject.csv_to_hash(csv_fixture)[1]["array"]).to eq ["red", "red", "omg"]
      end
    end

    context 'when csv contains header only' do
      let(:csv_fixture) do
        "id,string,hash_nested.adjustment,hash_nested.tax,hash_nested.shipping.airplane,hash_nested.shipping.land.north,hash_nested.shipping.land.south,array_of_hashes.0.id,array_of_hashes.0.status,array_of_hashes.1.id,array_of_hashes.1.status,array.0,array.1,array.2,array_with_hash.0,array_with_hash.1.a,array_with_hash.1.b,array_with_nested_array.0,array_with_nested_array.1.0,array_with_nested_array.1.1,array_with_nested_array.2.0.0.0"
      end

      it 'returns an empty array' do
        expect(subject.csv_to_hash(csv_fixture)).to eq []
      end
    end

    context 'when csv is empty' do
      let(:csv_fixture) { "" }

      it 'returns an empty array' do
        expect(subject.csv_to_hash(csv_fixture)).to eq []
      end
    end
  end
end
