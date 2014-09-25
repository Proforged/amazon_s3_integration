require 'spec_helper'

describe Converter do
  subject { described_class }

  describe '.json_to_csv' do
    let(:json) do
      {
        id: "R154085346541340",
        string: "USD",
        hash_nested: {
          adjustment: 20,
          tax: 10,
          shipping: {
            airplane: 5,
            land: {
              north: 1,
              south: 2
            }
          }
        },
        array_of_hashes: [{
          id: 1,
          status: "shipped"
        }, {
          id: 2,
          status: "ready"
        }],
        array: ["red", "green", "refactor"],
        array_with_hash: [10, { a: 1, b: 2 }],
        array_with_nested_array: ["yes", ["no", "nope"], [[["maybe"]]]]
      }
    end

    it 'works' do
      expect(subject.header(json)).to eq([
        "id", "string", "hash_nested.adjustment", "hash_nested.tax", "hash_nested.shipping.airplane", "hash_nested.shipping.land.north", "hash_nested.shipping.land.south", "array_of_hashes.0.id", "array_of_hashes.0.status", "array_of_hashes.1.id", "array_of_hashes.1.status", "array.0", "array.1", "array.2", "array_with_hash.0", "array_with_hash.1.a", "array_with_hash.1.b", "array_with_nested_array.0", "array_with_nested_array.1.0", "array_with_nested_array.1.1", "array_with_nested_array.2.0.0.0"
      ])
    end
  end
end
