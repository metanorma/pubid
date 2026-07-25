# frozen_string_literal: true

module Pubid
  # IETF flavor: one module covering the three IETF document families that share
  # the IETF publisher and the `urn:ietf:` namespace —
  #   * RFC              (e.g. "RFC 2119")     -> Identifiers::Rfc
  #   * RFC sub-series   (BCP/STD/FYI)         -> Identifiers::Bcp/Std/Fyi
  #   * Internet-Drafts  (e.g. "draft-...-02") -> Identifiers::InternetDraft
  module Ietf
    extend Pubid::PrefixesSupport

    # Leading tokens a printed IETF id can begin with. "draft" covers the
    # "draft-<slug>" Internet-Draft form. No joint/co-publication prefixes.
    PREFIXES = ["RFC", "BCP", "STD", "FYI", "draft"].freeze

    autoload :Builder, "#{__dir__}/ietf/builder"
    autoload :Identifier, "#{__dir__}/ietf/identifiers/base"
    autoload :Identifiers, "#{__dir__}/ietf/identifiers"
    autoload :Parser, "#{__dir__}/ietf/parser"
    autoload :Renderer, "#{__dir__}/ietf/renderer"
    autoload :UrnGenerator, "#{__dir__}/ietf/urn_generator"
    autoload :UrnParser, "#{__dir__}/ietf/urn_parser"

    # Parse an IETF identifier string
    def self.parse(identifier)
      # Inline length guard (CodeQL rb/polynomial-redos barrier) before the
      # normalization/parse path — must be the first statement.
      raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE if identifier.length > Pubid::MAX_INPUT_LENGTH

      Identifier.parse(identifier)
    end

    # Per-flavor format registry: inherits global formats, overrides :human
    Identifier.format_registry = FormatRegistry.new(parent: Identifier.format_registry)
    Identifier.format_registry.register(:human, renderer: Ietf::Renderer)

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

# Register IETF flavor with the registry
Pubid::Registry.register(:ietf, Pubid::Ietf)
