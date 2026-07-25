# frozen_string_literal: true

module Pubid
  module Sae
    extend Pubid::PrefixesSupport

    # Sole SAE publisher token (see the parser's `publisher` rule). Document
    # types (AMS/AIR/ARP/AS/J/MA) follow the SAE prefix and are excluded.
    PREFIXES = ["SAE"].freeze

    autoload :Builder, "#{__dir__}/sae/builder"
    autoload :Components, "#{__dir__}/sae/components"
    autoload :Identifier, "#{__dir__}/sae/identifiers/base"
    autoload :Identifiers, "#{__dir__}/sae/identifiers"
    autoload :Parser, "#{__dir__}/sae/parser"
    autoload :Renderer, "#{__dir__}/sae/renderer"
    autoload :UrnGenerator, "#{__dir__}/sae/urn_generator"
    autoload :UrnParser, "#{__dir__}/sae/urn_parser"

    def self.parse(input)
      Identifier.parse(input)
    end

    # Auto-discover all identifier types from the Identifiers namespace.
    # SAE has only one identifier class (Base), which IS the document type.
    # @return [Array<Class>] identifier classes (Pubid::Identifier subclasses)
    def self.identifier_types
      @identifier_types ||= Identifiers.constants
        .filter_map { |c| begin; Identifiers.const_get(c); rescue NameError; nil; end }
        .select { |c| c.is_a?(Class) && c < Pubid::Identifier }
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

Pubid::Registry.register(:sae, Pubid::Sae)

# Per-flavor format registry: inherits global formats, overrides :human
Pubid::Sae::Identifier.format_registry = Pubid::FormatRegistry.new(parent: Pubid::Identifier.format_registry)
Pubid::Sae::Identifier.format_registry.register(:human, renderer: Pubid::Sae::Renderer)
