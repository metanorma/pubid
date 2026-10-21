# frozen_string_literal: true

require "pubid"
require "lutaml/model"

module Pubid
  module Iso
    extend Pubid::PrefixesSupport

    # Sole ISO publisher token. Joint / co-publication forms (ISO/IEC, IEC/ISO,
    # ISO/IEC/IEEE) are contributed symmetrically via Pubid::JOINT_PREFIXES.
    PREFIXES = ["ISO"].freeze

    autoload :Builder, "#{__dir__}/iso/builder"
    autoload :BundledIdentifier, "#{__dir__}/iso/bundled_identifier"
    autoload :CombinedIdentifier, "#{__dir__}/iso/combined_identifier"
    autoload :Components, "#{__dir__}/iso/components"
    autoload :FormatResolver, "#{__dir__}/iso/format_resolver"
    autoload :Identifier, "#{__dir__}/iso/identifier"
    autoload :Identifiers, "#{__dir__}/iso/identifiers"
    autoload :Normalizer, "#{__dir__}/iso/normalizer"
    autoload :Parser, "#{__dir__}/iso/parser"
    autoload :RenderingStyle, "#{__dir__}/iso/rendering_style"
    autoload :SingleIdentifier, "#{__dir__}/iso/single_identifier"
    autoload :SupplementIdentifier, "#{__dir__}/iso/supplement_identifier"
    autoload :UrnGenerator, "#{__dir__}/iso/urn_generator"
    autoload :UrnParser, "#{__dir__}/iso/urn_parser"
    autoload :Utilities, "#{__dir__}/iso/utilities"

    # Parse an ISO identifier string
    # @param identifier [String] the identifier string to parse
    # @param format [Symbol] :auto, :human, :mr_string, or :urn
    # @return [Identifier] the parsed identifier
    def self.parse(identifier, format: :auto)
      unless identifier.is_a?(String)
        raise Pubid::Errors::InvalidInputError,
              Pubid::INPUT_NOT_A_STRING_MESSAGE
      end

      if identifier.length > Pubid::MAX_INPUT_LENGTH
        raise Pubid::Errors::InvalidInputError, Pubid::INPUT_TOO_LONG_MESSAGE
      end

      format = Pubid::FormatDetector.detect(identifier) if format == :auto

      case format
      when :urn
        UrnParser.parse(identifier)
      when :mr_string
        Pubid::Parsers::MrString.parse(identifier)
      else
        Normalizer.apply(identifier)
      end
    end

    # Build an ISO identifier from attributes.
    #
    # This is the public seam: callers in other flavors should never reach
    # into `Pubid::Iso::Identifiers::*` or `Pubid::Iso::Components::*`
    # directly — go through this method so the internal class registry can
    # change without breaking callers.
    #
    # Accepts either raw values (Strings/Integers) or pre-built components.
    # Raw values are wrapped in the appropriate ISO component internally.
    #
    # @param type [Symbol] the type key (e.g. :is, :tr, :ts, :guide)
    # @param publisher [String, Pubid::Iso::Components::Publisher] primary publisher
    # @param copublishers [Array<String>, Array<Pubid::Components::Publisher>]
    # @param number [String, Integer]
    # @param year [String, Integer, Pubid::Components::Date, nil]
    # @param attrs [Hash] additional identifier attributes
    # @return [Pubid::Iso::Identifier]
    def self.build(type:, publisher: nil, copublishers: nil, number: nil,
                   year: nil, **attrs)
      klass = locate_type(type) || raise(ArgumentError, "unknown ISO type: #{type.inspect}")

      copub_list = Array(copublishers)
      attrs[:publisher] = build_publisher(publisher, copub_list) if publisher || copub_list.any?
      attrs[:copublishers] = build_copublishers(copub_list) if copub_list.any?
      attrs[:number] = build_code(number) if number
      attrs[:date] = build_date(year) if year

      klass.new(attrs)
    end

    # @!visibility private
    def self.build_publisher(value, copublishers = [])
      return value if value.is_a?(Components::Publisher) && copublishers.empty?

      copub_strings = copublishers.map { |cp| cp.is_a?(Components::Publisher) ? cp.publisher : cp.to_s }
      Components::Publisher.new(
        publisher: value.is_a?(Components::Publisher) ? value.publisher : value.to_s,
        copublisher: copub_strings,
      )
    end
    private_class_method :build_publisher

    # @!visibility private
    def self.build_copublishers(list)
      Array(list).map do |cp|
        next cp if cp.is_a?(Components::Publisher)

        Components::Publisher.new(publisher: cp.to_s)
      end
    end
    private_class_method :build_copublishers

    # @!visibility private
    # number/part/subpart are plain strings. A caller that still passes a
    # Components::Code (another flavor's builder, a hand-built id) is read
    # through its own #to_s rather than refused.
    def self.build_code(value)
      value.to_s
    end
    private_class_method :build_code

    # @!visibility private
    def self.build_date(value)
      return value if value.is_a?(::Pubid::Components::Date)

      ::Pubid::Components::Date.new(year: value.to_s)
    end
    private_class_method :build_date

    # Parse an ISO URN string
    # @param urn [String] the URN string to parse
    # @return [Identifier] the parsed identifier
    # @raise [Errors::ParseError] if URN is invalid
    def self.parse_urn(urn)
      UrnParser.parse(urn)
    end

    # Build an ISO identifier from a Parslet parse-tree hash (used by other
    # flavors when parsing joint identifiers, e.g. IEC's `IEC … | ISO …` form).
    #
    # This is the public seam: callers should never reach into
    # `Pubid::Iso::Builder` directly.
    #
    # @param hash [Hash] parse tree for an ISO identifier
    # @return [Pubid::Iso::Identifier]
    def self.build_from_parse(hash)
      builder.build(hash)
    end

    # Return the named Parslet rule atom from the ISO parser, for embedding in
    # another flavor's grammar (e.g. IEC joint identifiers).
    #
    # This is the public seam: callers should never instantiate
    # `Pubid::Iso::Parser` directly.
    #
    # @param rule_name [Symbol] the parser rule to expose
    # @return [Parslet::Atoms::Base]
    def self.joint_grammar_atom(rule_name)
      parser.public_send(rule_name)
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

    # Memoized builder instance used by Normalizer / URN parser
    # @return [Pubid::Iso::Builder]
    def self.builder
      @builder ||= Builder.new
    end

    # Memoized parser instance used by Normalizer
    # @return [Pubid::Iso::Parser]
    def self.parser
      @parser ||= Parser.new
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

    # Lookup: stage code -> typed stage
    # @param stage_code [String, Symbol]
    # @return [Pubid::Components::TypedStage, nil]
    def self.locate_stage_by_stage_code(stage_code)
      stage_code_sym = stage_code.to_sym
      all_typed_stages.find { |s| s.stage_code.to_sym == stage_code_sym }
    end

    # Lookup: per-typed-stage code -> typed stage
    # @param code [String, Symbol]
    # @return [Pubid::Components::TypedStage, nil]
    def self.locate_stage_by_code(code)
      code_sym = code.to_sym
      all_typed_stages.find { |s| s.code&.to_sym == code_sym }
    end

    # Lookup: harmonized stage code -> typed stage
    # @param harmonized_code [String]
    # @return [Pubid::Components::TypedStage, nil]
    def self.locate_stage_by_harmonized_code(harmonized_code)
      harmonized_str = harmonized_code.to_s
      candidates = all_typed_stages.select { |s| s.harmonized_stages&.include?(harmonized_str) }
      # all_typed_stages walks the loaded identifier constants, so its order
      # is load-order dependent and a bare "first match" flipped between
      # processes (an IWA at 10.99 rendered "AWI Add"/"AWI Suppl"/"AWI"
      # depending on the run). The IS family is the default document type;
      # prefer it, then keep the registry order.
      candidates.find { |s| s.type_code.to_s == "is" } || candidates.first
    end

    # Default typed stage used when no type_with_stage is present
    # (e.g., the bare International Standard published stage)
    # @return [Pubid::Components::TypedStage]
    def self.default_typed_stage
      locate_stage("") || all_typed_stages.first
    end
  end
end

Pubid::Registry.register(:iso, Pubid::Iso)
