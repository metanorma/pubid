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
            code = identifier.code.to_s
            parts << "#{series}.#{code}"
          else
            parts << series
          end
        elsif identifier.code
          code = identifier.code.to_s
          parts << code
        end

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
          # An annex base holds its identity in its own base (its sector/series/
          # code are nil), so generate_base_urn would emit "urn:itu:itu"
          # for it — go through its own to_urn instead.
          base_urn = if base.is_a?(Identifiers::AnnexOfRecommendation)
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
              code = identifier.code.to_s
              parts << "#{series}.#{code}"
            else
              parts << series
            end
          end
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
