# frozen_string_literal: true

module Pubid
  module Itu
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        if identifier.is_a?(Identifiers::Supplement)
          generate_supplement_urn
        else
          generate_base_urn
        end
      end

      protected

      def generate_base_urn
        parts = ["urn", "itu"]

        if identifier.sector
          sector = identifier.sector.to_s
          parts << sector.to_s.downcase
        else
          parts << "itu"
        end

        if identifier.series
          series = identifier.series.to_s
          if identifier.code
            # A series-code document joins with a dash, not a dot; rendering it
            # "EMC.5" would be ambiguous with a hypothetical "ITU-T EMC.5" and
            # would not parse back.
            join = identifier.series_dash ? "-" : "."
            parts << "#{series}#{join}#{identifier.code.compact_s}"
          else
            parts << series
          end
        elsif identifier.code
          code = identifier.code.compact_s
          parts << code
        end

        # Identity-bearing markers that are not part of sector/series/code.
        # Without them "ITU-T H.350 attachment", "ITU-T Q.120-Q.139" and
        # "ITU-T E-100 series Suppl. 2" would each share a URN with the
        # document they are distinct from — the same collision Code#compact_s
        # exists to prevent for the code suffixes.
        parts << "series" if identifier.series_word
        parts << "attachment" if identifier.attachment
        parts << "to-#{identifier.range_end}" if identifier.range_end

        if identifier.date
          date = identifier.date
          if date&.year && date.month
            parts << "#{date.month}/#{date.year}"
          elsif date&.year
            parts << date.year.to_s
          end
        end

        if identifier.language
          parts << identifier.language.to_s.downcase
        end

        parts.join(":")
      end

      def generate_supplement_urn
        parts = ["urn", "itu"]

        base = maybe(:base)
        if base
          # An annex or appendix base holds its identity in its OWN base (its
          # sector/series/code are nil), so generate_base_urn would emit
          # "urn:itu:itu" for it — go through its own to_urn instead.
          nested_wrapper = base.is_a?(Identifiers::AnnexOfRecommendation) ||
            base.is_a?(Identifiers::AppendixOfRecommendation)
          base_urn = if nested_wrapper
                       base.to_urn
                     else
                       self.class.new(base).generate_base_urn
                     end

          base_part = base_urn.sub(/^urn:itu:/, "")
          base_parts = base_part.split(":")

          parts.concat(base_parts)
        else
          if identifier.sector
            sector = identifier.sector.to_s
            parts << sector.to_s.downcase
          end
          if identifier.series
            series = identifier.series.to_s
            if identifier.code
              code = identifier.code.compact_s
              parts << "#{series}.#{code}"
            else
              parts << series
            end
          end
          # A base-less supplement's whole identity is sector + series, so the
          # series-group word belongs in the URN too — without it
          # "ITU-T E-100 series Suppl. 2" and "ITU-T E-100 Suppl. 2" collide.
          parts << "series" if identifier.series_word
        end

        supplement_notation = maybe(:supplement_notation)
        if supplement_notation
          parts << supplement_notation.to_s.downcase
        end

        if identifier.number
          parts << identifier.number.to_s
        end

        if identifier.date
          date = identifier.date
          if date&.year && date.month
            parts << "#{date.month}/#{date.year}"
          elsif date&.year
            parts << date.year.to_s
          end
        end

        parts.join(":")
      end
    end
  end
end
