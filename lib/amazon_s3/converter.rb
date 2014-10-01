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

    def hash_to_csv(hash)
      header = csv_header(hash)

      output = header.inject([]) do |buff, column|
        buff.push json_path(hash, column)
      end

      [header.join(","), output.join(",")].join("\n")
    end

    def csv_to_json(csv)
      header, values = csv.split("\n")

      header = header.split(",")
      values = values.split(",")

      header.each_with_index.inject({}) do |buff, (path, index)|
        json_path_set(buff, path, values[index])
      end
    end

    def json_path_set(json, path, value)
      return value if path == ""

      current = leftmost_path(path)

      if current.to_i.to_s == current #number?
        json = [] unless json.is_a? Array
        case json[current.to_i]
        when nil
          json[current.to_i] = json_path_set({}, rest_of_path(path), value)
        else
          json[current.to_i] = json_path_set(json[current.to_i], rest_of_path(path), value)
        end
      else
        case json[current]
        when Array
          json[current] = json_path_set(json[current], rest_of_path(path), value)
        when Hash
          json[current].deep_merge! json_path_set({}, rest_of_path(path), value)
        when nil
          json[current] = json_path_set({}, rest_of_path(path), value)
        end
      end

      json
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
