module Pubid::Iso
  class Type
    attr_accessor :type

    TYPE_NAMES = {
      tr: {
        long: "Technical Report",
        short: "TR",
      },
      ts: {
        long: "Technical Specification",
        short: "TS",
      },
      is: {
        long: "International Standard",
        short: "IS",
      },
      pas: {
        long: "Publicly Available Specification",
        short: "PAS",
      },
      isp: {
        long: "International Standardized Profiles",
        short: "ISP",
      },
      guide: {
        long: "Guide",
        short: "Guide",
      },
      dir: {
        long: "Directives",
        short: "DIR",
      },
      dpas: {
        long: "Publicly Available Specification Draft",
        short: "DPAS",
      },
      cor: {
        short: "Cor",
      },
      amd: {
        short: "Amd",
      },
    }.freeze

    # Create new type
    # @param type [Symbol]
    def initialize(type)
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

      type == other.type
    end

    def self.has_type?(type)
      TYPE_NAMES.any? do |_, v|
        v[:short] == type
      end
    end
  end
end
