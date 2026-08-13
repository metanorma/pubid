# frozen_string_literal: true

module Pubid
  module Ieee
    extend Pubid::PrefixesSupport

    # Publisher prefix. The private PreParser::PUBLISHERS list also holds adopted
    # co-org names (ANSI, AIEE, ASA, ...) that are not leading routing tokens for
    # an IEEE reference, so they are deliberately excluded. The joint ISO/IEC/IEEE
    # form comes from Pubid::JOINT_PREFIXES.
    PREFIXES = ["IEEE"].freeze

    autoload :Aiee, "#{__dir__}/ieee/aiee"
    autoload :Builder, "#{__dir__}/ieee/builder"
    autoload :Identifier, "#{__dir__}/ieee/identifiers/base"
    autoload :Identifiers, "#{__dir__}/ieee/identifiers"
    autoload :Ire, "#{__dir__}/ieee/ire"
    autoload :Nesc, "#{__dir__}/ieee/nesc"
    autoload :Parser, "#{__dir__}/ieee/parser"
    autoload :PreParser, "#{__dir__}/ieee/pre_parser"
    autoload :Compaction, "#{__dir__}/ieee/compaction"
    autoload :Renderer, "#{__dir__}/ieee/renderer"
    autoload :TypedStages, "#{__dir__}/ieee/typed_stages"
    autoload :UrnGenerator, "#{__dir__}/ieee/urn_generator"
    autoload :UrnParser, "#{__dir__}/ieee/urn_parser"

    # Components submodule
    module Components
      autoload :Code, "#{__dir__}/ieee/components/code"
      autoload :Draft, "#{__dir__}/ieee/components/draft"
      autoload :Relationship, "#{__dir__}/ieee/components/relationship"
      autoload :TypedStage, "#{__dir__}/ieee/components/typed_stage"
    end

    # Document-number series carrying an IEEE registered trademark ("®").
    # 8802 is the ISO/IEC co-published form of the 802 series.
    REGISTERED_SERIES = %w[802 8802 2030].freeze

    # The ISO/IEC adoption of IEEE 802: the number alone identifies the series,
    # whatever publishers are printed.
    ISO_ADOPTED_SERIES = "8802"

    class << self
      def parse(input)
        if input.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        Identifier.parse(input)
      end

      # True when the document number belongs to a registered-trademark series.
      # A project number keeps its series identity, so a leading "P" is
      # stripped. `prefix` is the code's letter series, which must be absent
      # (or the bare project "P") — "C802.1" is a different series that merely
      # starts with the same digits. `publishers` guards against claiming an
      # IEEE registered mark for another body that happens to have numbered a
      # document 802 or 2030 — "AIEE Std No. 802" predates the IEEE 802 series
      # by two decades. It is optional: with no publishers given the number
      # decides, which keeps the plain number lookup usable on its own.
      # @param number [String, nil] bare document number ("802", "P802")
      # @param prefix [String, nil] letter series of the code ("C" for C37.09)
      # @param publishers [Array<String>, String, nil] printed publisher tokens
      def registered_series?(number, prefix = nil, publishers: nil)
        return false unless prefix.nil? || prefix.to_s.empty? ||
          prefix.to_s == "P"

        bare = number.to_s.delete_prefix("P")
        return false unless REGISTERED_SERIES.include?(bare)
        return true if bare == ISO_ADOPTED_SERIES || publishers.nil?

        Array(publishers).any? { |p| p.to_s.split("/").include?("IEEE") }
      end

      # IEEE trademark symbol for a document number: ® for the registered
      # series, ™ for everything else. This is the entry point render sites
      # use, because they hold the identifier and so know its number — the
      # symbol must not depend on where in the rendered string the mark lands.
      def trademark_symbol_for(number, prefix = nil, publishers: nil)
        if registered_series?(number, prefix, publishers: publishers)
          "®"
        else
          "™"
        end
      end

      # IEEE trademark symbol for a rendered identifier string. Kept for
      # external callers only — every render site inside pubid passes the
      # document number to #trademark_symbol_for instead, because the first
      # numeric token of a rendered string is not reliably the document number
      # (a NESC or IRE string starts with the publication year).
      def trademark_symbol(rendered)
        trademark_symbol_for(rendered.to_s[/(?<![0-9A-Za-z])P?(\d+)/, 1])
      end

      # Auto-discover all identifier types from the Identifiers namespace
      # @return [Array<Class>] identifier classes that define a self.type Hash
      def identifier_types
        @identifier_types ||= Identifiers.constants
          .filter_map { |c| begin; Identifiers.const_get(c); rescue NameError; nil; end }
          .select { |c| c.is_a?(Class) && c.singleton_methods(false).include?(:type) }
          .select { |c| c.type.is_a?(Hash) }
      end

      # Build typed stage index from TypedStages module
      # @return [Array<Pubid::Components::TypedStage>] all typed stages
      def all_typed_stages
        @all_typed_stages ||= TypedStages::TYPED_STAGES
      end

      # Lookup: type code -> identifier class
      # @param code [String, Symbol] the type key to find
      # @return [Class, nil] the matching identifier class
      def locate_type(code)
        identifier_types.find { |t| t.type[:key].to_s == code.to_s }
      end

      # Lookup: abbreviation -> typed stage
      # @param abbr [String, Symbol] the abbreviation to find
      # @return [Pubid::Components::TypedStage, nil] the matching typed stage
      def locate_stage(abbr)
        abbr_str = abbr.to_s.upcase
        all_typed_stages.find { |s| s.abbr.any? { |a| a.to_s.upcase == abbr_str } }
      end

      # Lookup: IEEE draft notation -> typed stage
      # @param draft [String] IEEE draft notation (e.g., "D1", "D5", "P")
      # @return [Pubid::Components::TypedStage, nil] the matching typed stage
      def locate_stage_by_ieee_draft(draft)
        return nil if draft.nil? || draft.to_s.strip.empty?

        draft_str = draft.to_s.strip

        # Try exact match on abbreviation first
        ts = all_typed_stages.find { |t| t.abbr.include?(draft_str) }
        return ts if ts

        # Try match on ieee_draft_equivalent
        all_typed_stages.find { |t| t.ieee_draft_equivalent == draft_str }
      end

      # Lookup: ISO stage code -> typed stage
      # @param stage [String] ISO stage code (e.g., "WD", "CD", "DIS", "FDIS")
      # @return [Pubid::Components::TypedStage, nil] the matching typed stage
      def locate_stage_by_iso_stage(stage)
        return nil if stage.nil? || stage.to_s.strip.empty?

        all_typed_stages.find { |ts| ts.iso_stage_equivalent == stage.to_s.strip }
      end
    end
  end
end

Pubid::Registry.register(:ieee, Pubid::Ieee)

# Per-flavor format registry: inherits global formats, overrides :human
Pubid::Ieee::Identifier.format_registry = Pubid::FormatRegistry.new(parent: Pubid::Identifier.format_registry)
Pubid::Ieee::Identifier.format_registry.register(:human, renderer: Pubid::Ieee::Renderer)
