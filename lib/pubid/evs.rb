# frozen_string_literal: true

require "pubid"
module Pubid
  module Evs
    extend Pubid::PrefixesSupport

    # Leading tokens a printed EVS reference can start with, drawn from the
    # reference PDFs in metanorma/mn-samples-evs-private. Longest first so
    # prefix routing picks the most specific claim. Deliberately EXCLUDES the
    # bare adopted forms ("EN …" alone routes to Pubid::CenCenelec).
    PREFIXES = [
      "EVS-EN ISO/IEC", "EVS-EN ISO", "EVS-EN",
      "EVS EN ISO/IEC", "EVS EN ISO", "EVS EN",
      "EVS"
    ].freeze

    autoload :Builder, "#{__dir__}/evs/builder"
    autoload :Identifier, "#{__dir__}/evs/identifier"
    autoload :Identifiers, "#{__dir__}/evs/identifiers"
    autoload :Parser, "#{__dir__}/evs/parser"
    autoload :Renderer, "#{__dir__}/evs/renderer"
    autoload :UrnGenerator, "#{__dir__}/evs/urn_generator"
    autoload :UrnParser, "#{__dir__}/evs/urn_parser"

    def self.parse(identifier)
      unless identifier.is_a?(String)
        raise Pubid::Errors::InvalidInputError,
              Pubid::INPUT_NOT_A_STRING_MESSAGE
      end

      if identifier.length > Pubid::MAX_INPUT_LENGTH
        raise Pubid::Errors::InvalidInputError, Pubid::INPUT_TOO_LONG_MESSAGE
      end

      # The trailing language code (" et" / " en" / " et-en") extracts
      # before the grammar runs — the CEN adopted_string is greedy over
      # plain text and would swallow it.
      language = identifier[/ (et-en|et|en)\z/, 1]
      body = language ? identifier.sub(/ #{Regexp.escape(language)}\z/, "") : identifier

      parsed = Pubid::Parg::Backend.parse(:evs, body)
      built = Builder.new.build(parsed)
      built.language = language
      built
    end

    # Build an EVS identifier from a parse-tree hash.
    # @param hash [Hash] parse tree
    # @return [Pubid::Evs::Identifier]
    def self.build_from_parse(hash)
      Builder.new.build(hash)
    end

    # Per-flavor format registry: inherits global formats, overrides :human.
    Identifier.format_registry = FormatRegistry.new(parent: Identifier.format_registry)
    Identifier.format_registry.register(:human, renderer: Evs::Renderer)

    # Auto-discover all identifier types from the Identifiers namespace.
    # @return [Array<Class>]
    def self.identifier_types
      @identifier_types ||= Identifiers.constants.filter_map do |c|
        begin
          Identifiers.const_get(c)
        rescue NameError
          nil
        end
      end
        .select { |c| c.is_a?(Class) && c.singleton_methods(false).include?(:type) }
        .select { |c| c.type.is_a?(Hash) }
    end

    # EVS identifiers have no typed stages.
    # @return [Array<Pubid::Components::TypedStage>]
    def self.all_typed_stages
      @all_typed_stages ||= identifier_types.flat_map do |klass|
        klass.const_defined?(:TYPED_STAGES) ? klass.const_get(:TYPED_STAGES) : []
      end
    end

    # Lookup: type code -> identifier class
    # @param code [String, Symbol]
    # @return [Class, nil]
    def self.locate_type(code)
      identifier_types.find { |t| t.type[:key].to_s == code.to_s }
    end

    # Lookup: abbreviation -> typed stage
    # @param _abbr [String, Symbol]
    # @return [nil] EVS identifiers have no typed stages
    def self.locate_stage(_abbr)
      nil
    end
  end
end

# Register EVS flavor with the registry
Pubid::Registry.register(:evs, Pubid::Evs)
