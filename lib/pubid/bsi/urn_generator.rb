# frozen_string_literal: true

module Pubid
  module Bsi
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        parts = ["urn", "bsi"]

        if identifier.publisher
          pub = identifier.publisher.to_s
          parts << pub.to_s.downcase
        else
          parts << "bs"
        end

        if identifier.prefix
          parts << identifier.prefix.to_s.downcase
        end

        if identifier.flex_prefix
          parts << identifier.flex_prefix.to_s.downcase
        end

        # Fall back to the wrapped document's number. A wrapper — an adopted
        # European norm, a bundle, a set — carries no number of its own, and
        # `AdoptedEuropeanNorm#number` only delegates ONE level, so a
        # "DD ENV ISO 11079:1999" (which adopts a CEN prestandard that is
        # itself a wrapper around the ISO standard) emitted the identity-free
        # `urn:bsi:dd` — the same URN as every other DD adoption. `#root`
        # recurses to the origin document, and for a non-wrapper it is `self`,
        # so this changes nothing for an ordinary identifier.
        urn_number = identifier.number || identifier.root.number
        if urn_number
          number = urn_number.to_s
          if identifier.iteration && !identifier.iteration.empty?
            number += "[#{identifier.iteration}]"
          end
          parts << number
        end

        if identifier.part
          part = identifier.part.to_s
          parts << "-#{part}"
        end

        if identifier.subpart
          subpart = identifier.subpart.to_s
          parts << "-#{subpart}"
        end

        if identifier.second_number
          second = identifier.second_number.to_s
          parts << "/#{second}"
        end

        if identifier.date&.is_a?(::Pubid::Components::Date) && identifier.date.present?
          parts << identifier.date.render(context: URN_CONTEXT)
        elsif identifier.year
          parts << identifier.year.to_s
        end

        if identifier.month
          parts << format("%02d", identifier.month)
        end

        if identifier.edition
          parts << "v#{identifier.edition}"
        end

        if identifier.translation_lang
          parts << identifier.translation_lang.to_s.downcase
        elsif identifier.translation_upper
          parts << identifier.translation_upper.to_s.downcase
        end

        if identifier.type
          type = identifier.type&.abbr || identifier.type.to_s
          parts << type.to_s.downcase if type && type.to_s != "BS"
        end

        if identifier.typed_stage
          stage_code = identifier.typed_stage.stage_code
          if stage_code && stage_code != :published
            parts << "stage.#{stage_code}"
          end
        end

        parts.join(":")
      end
    end
  end
end
