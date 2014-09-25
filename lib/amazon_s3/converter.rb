class Converter
  class << self
    def json_to_csv(json, prefix = nil)
      return prefix unless ["Hash", "Array", "ActiveSupport::HashWithIndifferentAccess"].include? json.class.to_s

      json = json.with_indifferent_access
      keys = json.keys.map &:to_s

      if prefix
        keys = json.keys.map {|key| "#{prefix}.#{key}"}
      end

      keys.inject([]) do |final, key|
        if json[unprefix(key)].is_a? Hash
          final.push(*json_to_csv(json[unprefix(key)], key))
        elsif json[unprefix(key)].is_a? Array
          intermediate = []

          json[unprefix(key)].each_with_index do |object, index|
            intermediate.push(*json_to_csv(json[unprefix(key)][index], "#{key}.#{index}"))
          end

          final.push(*intermediate)
        else
          final.push(key)
        end
      end
    end

    def unprefix(key)
      key.split(".").last
    end
  end
end
