# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Etsi
    extend Pubid::PrefixesSupport

    # Sole ETSI publisher token (see the parser's `etsi_prefix` rule). The
    # document-type tokens (EN, TS, TR, ...) are sub-types that follow the ETSI
    # prefix, not standalone routing tokens, so they are excluded.
    PREFIXES = ["ETSI"].freeze

    autoload :Builder, "#{__dir__}/etsi/builder"
    autoload :Components, "#{__dir__}/etsi/components"
    autoload :Identifier, "#{__dir__}/etsi/identifiers/base"
    autoload :Identifiers, "#{__dir__}/etsi/identifiers"
    autoload :Parser, "#{__dir__}/etsi/parser"
    autoload :Renderer, "#{__dir__}/etsi/renderer"
    autoload :UrnGenerator, "#{__dir__}/etsi/urn_generator"
    autoload :UrnParser, "#{__dir__}/etsi/urn_parser"

    def self.parse(identifier)
      Identifier.parse(identifier)
    end

    # Per-flavor format registry: inherits global formats, overrides :human
    Identifier.format_registry = FormatRegistry.new(parent: ::Pubid::Identifier.format_registry)
    Identifier.format_registry.register(:human, renderer: Etsi::Renderer)

    # Auto-discover all identifier types from the Identifiers namespace
    # @return [Array<Class>] identifier classes (Pubid::Identifier subclasses)
    def self.identifier_types
      @identifier_types ||= Identifiers.constants
        .filter_map { |c| begin; Identifiers.const_get(c); rescue NameError; nil; end }
        .select { |c| c.is_a?(Class) && c < Pubid::Identifier }
        # Exclude the flavor base itself by identity (Identifier is now an
        # alias for Pubid::Etsi::Identifier, so name-based matching misses it).
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
  end
end

Pubid::Registry.register(:etsi, Pubid::Etsi)
