class Converter
  class << self
    def header(target, prefix = nil)
      case target
      when Hash
        target.map do |key, value|
          header(value, prepare_prefix(prefix, key))
        end.flatten
      when Array
        target.each_with_index.map do |object, i|
          header(object, prepare_prefix(prefix, i))
        end.flatten
      else
        prefix.to_s
      end
    end

    def prepare_prefix(a , b)
      return b unless a

      "#{a}.#{b}"
    end
  end
end
