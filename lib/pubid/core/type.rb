module Pubid::Core
  class Type
    attr_accessor :type
    # Create new type
    # @param type [Symbol]
    def initialize(type = DEFAULT_TYPE)
      type = type.to_s.downcase.to_sym unless type.is_a?(Symbol)

      raise Errors::WrongTypeError, "#{type} type is not available" unless TYPE_NAMES.key?(type)

      @type = type
    end

    def self.parse(type_string)
      TYPE_NAMES.each do |type, values|
        return new(type) if values[:short] == type_string
      end
      raise Errors::ParseTypeError, "Cannot parse '#{type_string}' type"
    end

    def to_s(format = :short)
      TYPE_NAMES[type][format]
    end

    def ==(other)
      return type == other if other.is_a?(Symbol)

      return false if other.nil?

      type == other.type
    end

    def self.has_type?(type)
      TYPE_NAMES.any? do |_, v|
        v[:short] == type
      end
    end
  end
end
