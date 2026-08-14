# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Itu
    module Components
      # ITU Code component
      # Format: [Imp]NUMBER[SUFFIX][.SUBSERIES][-PART]
      # Examples: 1234, 1234.5, 1234-1, 1234.5-2, 50bis, 8bis, Imp712, ImpOSI
      #
      # The optional "Imp" marker identifies an Implementers' Guide for the
      # series (e.g. G.Imp712, X.ImpOSI); the NUMBER that follows may be
      # digits or a short letter string.
      #
      # SUFFIX is the edition marker "bis" / "ter" / "quater" attached
      # directly to the number (e.g. X.50bis, V.8bis).
      #
      # Stays independent of Pubid::Components::Code because ITU uses
      # +subseries+ (dot-separated, flavor-specific) and +parts+
      # (dash-separated).
      class Code < Lutaml::Model::Serializable
        attribute :imp_marker, :string
        attribute :number, :string
        attribute :series_suffix, :string
        # ITU prints the edition word both glued ("X.50bis") and space-
        # separated ("E.250 bis"). The word itself is stored without the space,
        # so `series_suffix` stays a clean, whitespace-free value to compare and
        # index on; the spacing is this rendering-only flag. Named for the
        # rarer-in-code form so the `false` default stays out of `to_hash`.
        attribute :series_suffix_spaced, :boolean, default: -> { false }
        attribute :subseries, :string
        attribute :parts, :string, collection: true, default: []
        # A single trailing letter distinguishing variants of one
        # Recommendation: "D.200 R" (old D-series tariff recommendations),
        # "Q.2931 B", "R.38 A", the glued "D.502R" and the lowercase
        # "I.256.2a". Spaced is the majority spelling, so the glued one is the
        # flag.
        attribute :qualifier, :string
        attribute :qualifier_glued, :boolean, default: -> { false }

        # Segment order mirrors the grammar exactly — a GLUED suffix is
        # captured inside `standard_code` (the edition word before the
        # subseries, the qualifier after the parts), while a SPACED one is
        # captured afterwards by `code_suffixes`. Rendering the edition word
        # unconditionally first would print "Q.11a bis" back as "Q.11 bisa".
        def to_s
          result = "#{imp_marker}#{number}"
          result += series_suffix.to_s if series_suffix && !series_suffix_spaced
          result += ".#{subseries}" if subseries
          result += parts.map { |p| "-#{p}" }.join if parts&.any?
          result += qualifier.to_s if qualifier && qualifier_glued
          result += " #{series_suffix}" if series_suffix && series_suffix_spaced
          result += " #{qualifier}" if qualifier && !qualifier_glued
          result
        end

        # Space-free rendering for URN and MR use: the print form may separate
        # the edition word or the qualifier letter with a space ("E.250 bis",
        # "D.200 R"), which is not admissible inside a URN segment. Removing
        # the space keeps "D.200" and "D.200 R" on distinct URNs, which
        # dropping the suffix would not.
        def compact_s
          to_s.delete(" ")
        end

        def render(context: nil)
          to_s
        end

        def ==(other)
          return false unless other.is_a?(Code)

          imp_marker == other.imp_marker &&
            number == other.number &&
            series_suffix == other.series_suffix &&
            subseries == other.subseries &&
            parts == other.parts &&
            qualifier == other.qualifier
        end
      end
    end
  end
end
