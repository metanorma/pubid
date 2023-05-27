module Pubid::Ieee
  class Type
    attr_accessor :type

    TYPE_NAMES = {
      std: {
        long: "Standard",
        full: "Std",
        short: "Std",
        match: %w[STD Std Standard],
        alternative: "",
      },
      draft: {
        full: "Draft Std",
        short: "Draft Std",
        match: %w[Draft],
        alternative: "Draft",
      },
    }.freeze

    # Create new type
    # @param type [Symbol]
    def initialize(type = :std)
      type = type.to_s.downcase.to_sym unless type.is_a?(Symbol)

      raise Errors::WrongTypeError, "#{type} type is not available" unless TYPE_NAMES.key?(type)

      @type = type
    end

    def self.parse(type_string)
      TYPE_NAMES.each do |type, values|
        return new(type) if values[:match].include?(type_string)
      end
      raise Errors::ParseTypeError, "Cannot parse '#{type_string}' type"
    end

    def to_s(format = :short)
      TYPE_NAMES[type][format]
    end
  end
end
