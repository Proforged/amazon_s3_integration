require_relative 'converter'

class AmazonS3
  def initialize(s3_client:, bucket_name:)
    @s3_client = s3_client
    @bucket_name = bucket_name
  end

  def export(file_name:, folder_name:, object:)
    begin
      unless bucket.exists?
        return false, "Bucket '#{@bucket_name}' was not found."
      end

      aws_file_path = "#{folder_name}/#{file_name}.csv" # make it safe with regards to // and .csv.csv and check existence
      s3_object = bucket.objects[aws_file_path]
      s3_object.write(csv(object)) # do not overwrite, save as (1)

      [true, "File #{aws_file_path} was saved to s3"]
    rescue => e
      [false, e.message]
    end
  end

  def import(file_name:, folder_name:)
    begin
      unless bucket.exists?
        return false, "Bucket '#{@bucket_name}' was not found."
      end

      aws_file_path = "#{folder_name}/#{file_name}.csv" # make it safe with regards to // and .csv.csv and check existence
      s3_object = bucket.objects[aws_file_path]
      objects = Converter.csv_to_json(s3_object.read)
      object_count = objects.count

      summary = ""
      summary = "File #{aws_file_path} was read from S3 with #{object_count} object(s)." if object_count > 0

      [true, summary, objects]
    rescue => e
      [false, e.message]
    end
  end

  private
  def csv(hash)
    Converter.hash_to_csv(hash)
  end

  def bucket
    @s3_client.buckets[@bucket_name]
  end
end
