# frozen_string_literal: true

module Pubid
  module Ietf
    # Emits the canonical IETF URNs:
    #   RFC            -> urn:ietf:rfc:2119
    #   BCP/STD/FYI    -> urn:ietf:bcp:3 / urn:ietf:std:66 / urn:ietf:fyi:1
    #   Internet-Draft -> urn:ietf:id:draft-giuliano-treedn[:02]
    class UrnGenerator < Pubid::UrnGenerator::Base
      # The sub-series arm names its three classes explicitly rather than being
      # a catch-all `else`, because a bare Pubid::Ietf::Identifier has no
      # `series` reader at all — `series` is derived from the concrete class.
      def generate
        case identifier
        when Identifiers::Rfc then "urn:ietf:rfc:#{identifier.number}"
        when Identifiers::InternetDraft then draft_urn
        when Identifiers::Bcp, Identifiers::Std, Identifiers::Fyi
          "urn:ietf:#{identifier.series.downcase}:#{identifier.number}"
        else unsupported!
        end
      end

      private

      def draft_urn
        base = "urn:ietf:id:#{identifier.number}"
        identifier.version ? "#{base}:#{identifier.version}" : base
      end

      def unsupported!
        raise ArgumentError,
              "Cannot build a URN for #{identifier.class}: " \
              "not a concrete IETF identifier"
      end
    end
  end
end
