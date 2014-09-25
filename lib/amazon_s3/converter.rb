class Converter
  class << self
    def csv_header(target, prefix = nil)
      case target
      when Hash
        target.map do |key, value|
          csv_header(value, prepare_prefix(prefix, key))
        end.flatten
      when Array
        target.each_with_index.map do |object, i|
          csv_header(object, prepare_prefix(prefix, i))
        end.flatten
      else
        prefix.to_s
      end
    end

    def json_path(json, path)
      case json
      when Hash
        json = json.with_indifferent_access
        json_path(json[leftmost_path(path)], rest_of_path(path))
      when Array
        json_path(json[leftmost_path(path).to_i], rest_of_path(path))
      else
        path == "" ? json.to_s : "" # trying to traverse even more?
      end
    end

    def generate_csv(worst_case_json)
      header = csv_header(worst_case_json)

      output = header.inject([]) do |buff, column|
        buff.push json_path(worst_case_json, column)
      end

      [header.join(","), output.join(",")].join("\n")
    end

    private
    def rest_of_path(path)
      path.split(".")[1..-1].join(".")
    end

    def leftmost_path(path)
      path.split(".")[0]
    end

    def prepare_prefix(a , b)
      return b unless a

      "#{a}.#{b}"
    end
  end
end
