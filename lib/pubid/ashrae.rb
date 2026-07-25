# frozen_string_literal: true

module Pubid
  module Ashrae
    extend Pubid::PrefixesSupport

    # ASHRAE publisher token; the ANSI/ASHRAE joint form comes from
    # Pubid::JOINT_PREFIXES.
    PREFIXES = ["ASHRAE"].freeze

    autoload :Builder, "#{__dir__}/ashrae/builder"
    autoload :Identifier, "#{__dir__}/ashrae/identifiers/base"
    autoload :Identifiers, "#{__dir__}/ashrae/identifiers"
    autoload :Parser, "#{__dir__}/ashrae/parser"
    autoload :Renderer, "#{__dir__}/ashrae/renderer"
    autoload :SingleIdentifier, "#{__dir__}/ashrae/single_identifier"
    autoload :SupplementIdentifier, "#{__dir__}/ashrae/supplement_identifier"
    autoload :UrnGenerator, "#{__dir__}/ashrae/urn_generator"
    autoload :UrnParser, "#{__dir__}/ashrae/urn_parser"

    def self.parse(identifier)
      if identifier.length > Pubid::MAX_INPUT_LENGTH
        raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
      end

      Identifier.parse(identifier)
    end

    # Auto-discover all identifier types from the Identifiers namespace
    # @return [Array<Class>] identifier classes that define a self.type Hash
    def self.identifier_types
      @identifier_types ||= Identifiers.constants
        .filter_map { |c| begin; Identifiers.const_get(c); rescue NameError; nil; end }
        .select { |c| c.is_a?(Class) && c.singleton_methods(false).include?(:type) }
        .select { |c| c.type.is_a?(Hash) }
    end

    # Build typed stage index from identifier types
    # @return [Array<Pubid::Components::TypedStage>] all typed stages
    def self.all_typed_stages
      @all_typed_stages ||= identifier_types.flat_map do |klass|
        if klass.const_defined?(:TYPED_STAGES)
          klass.const_get(:TYPED_STAGES)
        else
          []
        end
      end
    end

    # Lookup: type code -> identifier class
    # @param code [String, Symbol] the type key to find
    # @return [Class, nil] the matching identifier class
    def self.locate_type(code)
      identifier_types.find { |t| t.type[:key].to_s == code.to_s }
    end

    # Lookup: abbreviation -> typed stage
    # @param abbr [String, Symbol] the abbreviation to find
    # @return [Pubid::Components::TypedStage, nil] the matching typed stage
    def self.locate_stage(abbr)
      abbr_str = abbr.to_s.upcase
      all_typed_stages.find { |s| s.abbr.any? { |a| a.to_s.upcase == abbr_str } }
    end
  end
end

# Register Uashrae flavor with the registry
Pubid::Registry.register(:ashrae, Pubid::Ashrae)

# Per-flavor format registry: inherits global formats, overrides :human
Pubid::Ashrae::Identifier.format_registry = Pubid::FormatRegistry.new(parent: Pubid::Identifier.format_registry)
Pubid::Ashrae::Identifier.format_registry.register(:human, renderer: Pubid::Ashrae::Renderer)
