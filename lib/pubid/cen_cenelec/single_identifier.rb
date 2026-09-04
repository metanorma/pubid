# frozen_string_literal: true

module Pubid
  module CenCenelec
    # The second of CEN/CENELEC's two identifier roots (the other is
    # Identifiers::Base); both descend from Pubid::CenCenelec::Identifier so every
    # concrete type is `is_a?` it.
    class SingleIdentifier < Pubid::CenCenelec::Identifier
      attribute :publisher, Components::Publisher, default: -> {
        Components::Publisher.new(body: "EN")
      }

      # Generate URN for this identifier
      #
      # @return [String] URN representation

      def self.type
        nil
      end

      def to_s(lang: :en, lang_single: false, **opts)
        render(format: :human, lang: lang, lang_single: lang_single, **opts)
      end

      def <=>(other)
        return nil unless other.is_a?(SingleIdentifier)

        # Compare by number first
        num_cmp = number.to_s <=> other.number.to_s
        return num_cmp unless num_cmp.zero?

        # Then by part
        part_cmp = (part || "0").to_s <=> (other.part || "0").to_s
        return part_cmp unless part_cmp.zero?

        # Then by date
        if date && other.date
          date.to_s <=> other.date.to_s
        elsif date
          1
        elsif other.date
          -1
        else
          0
        end
      end
    end
  end
end
