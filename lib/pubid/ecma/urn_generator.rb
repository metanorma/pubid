# frozen_string_literal: true

module Pubid
  module Ecma
    # Emits
    # `urn:ecma:<tag>:<number>[:part-<part>][:ed-<edition>][:vol-<volume>]`,
    # where the tag is bare for standards, "tr" for technical reports and "mem"
    # for mementos:
    #   ECMA-411          -> urn:ecma:411
    #   ECMA-418-1        -> urn:ecma:418:part-1
    #   ECMA TR/101       -> urn:ecma:tr:101
    #   ECMA MEM/1970     -> urn:ecma:mem:1970
    #   ECMA-269 ed3 vol2 -> urn:ecma:269:ed-3:vol-2
    #   ECMA-402 ed5.1    -> urn:ecma:402:ed-5.1
    #
    # The edition and volume segments are additive: they only ever split a
    # collision, so a URN minted before they existed still reads back (UrnParser
    # probes for the labelled prefix). They are needed because edition and
    # volume are identity-bearing — without them 804 published documents share
    # 421 URNs.
    #
    # The dot of a decimal edition is KEPT: "." is `unreserved` in RFC 8141, and
    # the URN has an inverse, so it must be lossless. (The MR string, which has
    # no inverse, collapses it to "ed5-1" instead.)
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        parts = ["urn", "ecma", identifier.type_prefix&.downcase,
                 identifier.number.to_s]
        parts.concat(labelled_segments)
        parts.compact.join(":")
      end

      private

      # Every optional field carries its own label, so a URN written before a
      # given label existed still reads back (UrnParser probes for the prefix).
      def labelled_segments
        {
          "part" => identifier.part,
          "ed" => identifier.edition,
          "vol" => identifier.volume,
        }.filter_map { |label, value| "#{label}-#{value}" if value }
      end
    end
  end
end
