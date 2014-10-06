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

    context 'hashes with different schemas' do
      it 'generates a csv with all the columns' do
        expect(
          subject.array_of_hashes_to_csv([ { a: 1, b: 1 }, { b: 2, c: 2 } ])
        ).to eq "a,b,c\n1,1,\n,2,2"
      end
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

    context 'when csv uses \r as line delimiter' do
      let(:csv_fixture) do
        "id,status,channel,email,currency,placed_on,totals.item,totals.adjustment,totals.tax,totals.shipping,totals.payment,totals.order,line_items.0.product_id,line_items.0.name,line_items.0.quantity,line_items.0.price,line_items.0.bigcommerce_id,line_items.0.bigcommerce_product_id,adjustments.0.name,adjustments.0.value,adjustments.1.name,adjustments.1.value,billing_address.firstname,billing_address.lastname,billing_address.address1,billing_address.address2,billing_address.zipcode,billing_address.city,billing_address.state,billing_address.country,billing_address.phone,payments.0.number,payments.0.status,payments.0.amount,payments.0.payment_method,bigcommerce_id,shipping_address.firstname,shipping_address.lastname,shipping_address.address1,shipping_address.address2,shipping_address.zipcode,shipping_address.city,shipping_address.state,shipping_address.country,shipping_address.phone,shipping_address.bigcommerce_id,updated_at,token,shipping_instructions,magento_order_id,totals.discount,totals.adjustments,line_items.0.product_type,adjustments.0.tax,adjustments.1.shipping,adjustments.2.name,adjustments.2.discount,shipping_method,source,line_items.0.options.0.Size,line_items.0.options.1.Color,line_items.0.options.0.Color,\r1NCU38QJA-107,awaiting fulfillment,bigcommerce_ncu38qja_manual,sameer@spreecommerce.com,USD,2014-10-03T21:30:17+00:00,19.99,9,0,10,28.99,28.99,SPR-00001,Spree Baseball Jersey,1,19.99,8,88,Shipping,10,Discount,-1,Sameer,Gulati,3333 Awesome Street,Unit 1,20814,Bethesda,Maryland,US,4084552962,N/A,completed,28.99,Credit Card,107,Sameer,Gulati,3333 Awesome Street,Unit 1,20814,Bethesda,Maryland,US,4084552962,8,2014-10-03T21:30:39Z,a235521078b8bcad,,,,,,,,,,,,,,,"
      end

      it 'works too' do
        expect(subject.csv_to_hash(csv_fixture).size).to eq 1
      end
    end
  end
end
