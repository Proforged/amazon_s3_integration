require_relative 'converter'

class AmazonS3
  def initialize(s3_client:, bucket_name:)
    @s3_client = s3_client
    @bucket_name = bucket_name
  end

  def export(file_name:, object:)
    verify_bucket!

    s3_object = bucket.objects[file_name] # make it safe with regards to // and .csv.csv and check existence
    s3_object.write(csv(object)) # do not overwrite, save as (1)

    "File #{file_name} was saved to s3"
  end

  def import(file_name:)
    verify_bucket!

    s3_object = bucket.objects[file_name]
    objects = Converter.csv_to_json(s3_object.read)
    object_count = objects.count

    summary = ""
    summary = "File #{file_name} was read from S3 with #{object_count} object(s)." if object_count > 0

    [summary, objects]
  end

  private
  def verify_bucket!
    raise "Bucket '#{@bucket_name}' was not found." unless bucket.exists?
  end

  def csv(hash)
    Converter.hash_to_csv(hash)
  end

  def bucket
    @s3_client.buckets[@bucket_name]
  end
end
