# frozen_string_literal: true

module Pubid
  module Iho
    extend Pubid::PrefixesSupport

    # Sole IHO publisher token (see the parser grammar).
    PREFIXES = ["IHO"].freeze

    autoload :Builder,      "#{__dir__}/iho/builder"
    autoload :Identifier, "#{__dir__}/iho/identifiers/base"
    autoload :Identifiers,  "#{__dir__}/iho/identifiers"
    autoload :Parser,       "#{__dir__}/iho/parser"
    autoload :Renderer,     "#{__dir__}/iho/renderer"
    autoload :UrnGenerator, "#{__dir__}/iho/urn_generator"
    autoload :UrnParser, "#{__dir__}/iho/urn_parser"

    # Parse an IHO identifier string into an identifier object
    # @param identifier [String] The IHO identifier string to parse
    # @return [Pubid::Iho::Identifier] The appropriate identifier object
    def self.parse(identifier)
      Identifier.parse(identifier)
    end

    # Per-flavor format registry: inherits global formats, overrides :human
    Identifier.format_registry = FormatRegistry.new(parent: ::Pubid::Identifier.format_registry)
    Identifier.format_registry.register(:human, renderer: Iho::Renderer)

    # Auto-discover all identifier types from the Identifiers namespace.
    # @return [Array<Class>] identifier classes (Pubid::Identifier subclasses)
    def self.identifier_types
      @identifier_types ||= Identifiers.constants
        .filter_map { |c| begin; Identifiers.const_get(c); rescue NameError; nil; end }
        .select { |c| c.is_a?(Class) && c < Pubid::Identifier }
        # Exclude the flavor base itself by identity (Identifier is now an
        # alias for Pubid::Iho::Identifier, so name-based matching misses it).
        .reject { |c| c == Identifier }
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

    # Look up an identifier class by its IHO series letter (S/P/M/B/C).
    # @param letter [String]
    # @return [Class<Identifier>]
    def self.identifier_klass_for_type_letter(letter)
      @by_letter ||= identifier_types.to_h { |klass| [klass.type[:short], klass] }
      @by_letter.fetch(letter.to_s)
    end
  end
end

Pubid::Registry.register(:iho, Pubid::Iho)
