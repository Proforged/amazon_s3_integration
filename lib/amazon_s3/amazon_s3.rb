require_relative 'converter'

class AmazonS3
  def initialize(s3_client:, bucket_name:)
    @s3_client = s3_client
    @bucket_name = bucket_name
  end

  def export(file_name:, objects:)
    verify_bucket!

    s3_object = find_next_s3_object(file_name)
    s3_object.write(csv(objects))

    "File #{s3_object.key} was saved to S3"
  end

  def import(file_name:)
    verify_bucket!

    objects = Converter.csv_to_hash(read_file!(file_name))
    object_count = objects.count

    summary = nil
    summary = "File #{file_name} was read from S3 with #{object_count} object(s)." if object_count > 0

    [summary, objects]
  end

  private
  def find_next_s3_object(file_name)
    s3_object = bucket.objects[file_name]

    # file.csv exists?
    # save it to file(1).csv or file(next_id).csv
    if s3_object.exists?
      prefix = file_name.gsub(".csv", "(")
      copies = bucket.objects.with_prefix(prefix).map do |s3_object|
        # extracts the id: already_exists/shipments(2).csv -> 2
        s3_object.key.match(/\A.*\((\d+)\)\.csv\z/)[1].to_i
      end

      next_id = copies.max.to_i + 1

      file_name = file_name.gsub(".csv", "(#{next_id}).csv")
      bucket.objects[file_name]
    else
      s3_object
    end
  end

  def read_file!(file_name)
    s3_object = bucket.objects[file_name]

    if s3_object.exists?
      contents = s3_object.read
      s3_object.delete
      contents
    else
      ""
    end
  end

  def verify_bucket!
    raise "Bucket '#{@bucket_name}' was not found." unless bucket.exists?
  end

  def csv(objects)
    Converter.array_of_hashes_to_csv(objects)
  end

  def bucket
    @s3_client.buckets[@bucket_name]
  end
end
