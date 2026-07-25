# frozen_string_literal: true

module Pubid
  module Amca
    extend Pubid::PrefixesSupport

    # AMCA publisher token; the ANSI/AMCA joint form comes from
    # Pubid::JOINT_PREFIXES.
    PREFIXES = ["AMCA"].freeze

    autoload :Identifier, "#{__dir__}/amca/identifiers/base"
    autoload :Identifiers, "#{__dir__}/amca/identifiers"
    autoload :Builder, "#{__dir__}/amca/builder"
    autoload :Parser, "#{__dir__}/amca/parser"
    autoload :Renderer, "#{__dir__}/amca/renderer"
    autoload :SingleIdentifier, "#{__dir__}/amca/single_identifier"
    autoload :UrnGenerator, "#{__dir__}/amca/urn_generator"
    autoload :UrnParser, "#{__dir__}/amca/urn_parser"

    # Parse an ACMA identifier string into an identifier object
    # @param identifier [String] The ACMA identifier string to parse
    # @return [Pubid::Amca::Identifier] The appropriate identifier object
    # @raise [Parslet::ParseFailed] If parsing fails
    def self.parse(identifier)
      Identifier.parse(identifier)
    end

    # Per-flavor format registry: inherits global formats, overrides :human
    Identifier.format_registry = FormatRegistry.new(parent: ::Pubid::Identifier.format_registry)
    Identifier.format_registry.register(:human, renderer: Amca::Renderer)

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

  # Register this flavor with the Pubid registry
end

# Register Uamca flavor with the registry
Pubid::Registry.register(:amca, Pubid::Amca)
