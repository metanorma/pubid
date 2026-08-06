# frozen_string_literal: true

module Pubid
  module Bipm
    # Inverts {UrnGenerator}, rebuilding the identifier directly from the URN
    # fields (rather than reconstructing a printed string) because the printed
    # forms carry surface detail — meeting ordinals, French wording — that the
    # canonical URN intentionally omits.
    class UrnParser < Pubid::UrnParser::Base
      def parse_urn(urn)
        body = strip_namespace(urn)
        parts = body.split(":", -1)

        case parts.first
        when "metrologia" then build_metrologia(parts)
        when "si-brochure" then build_si_brochure(parts)
        else build_group_leading(parts)
        end
      end

      private

      def build_group_leading(parts)
        group = parts[0].upcase
        if parts[1] == "meeting"
          Identifiers::Meeting.new(
            group: group, number: parts[2].to_s, year: parts[3]&.to_i,
          )
        else
          Identifiers::CommitteeDocument.new(
            group: group,
            type_code: (parts[1].empty? ? nil : parts[1].upcase),
            number: (parts[2].empty? ? nil : parts[2]), year: parts[3]&.to_i
          )
        end
      end

      def build_metrologia(parts)
        Identifiers::MetrologiaArticle.new(
          volume: parts[1]&.to_i, issue: parts[2], article: parts[3],
        )
      end

      def build_si_brochure(parts)
        Identifiers::SiBrochure.new(
          language: parts[1].to_s.upcase, edition: parts[2],
          version: parts[3], years: parts[4]
        )
      end
    end
  end
end
