# frozen_string_literal: true

module Pubid
  module Ecma
    # Parses ECMA URNs back into identifiers, inverting {UrnGenerator}.
    #
    # Examples:
    #   urn:ecma:411            -> ECMA-411
    #   urn:ecma:418:part-1     -> ECMA-418-1
    #   urn:ecma:tr:101         -> ECMA TR/101
    #   urn:ecma:mem:1970       -> ECMA MEM/1970
    #   urn:ecma:269:ed-3:vol-2 -> ECMA-269 ed3 vol2
    #
    # Every trailing segment is consumed only if it carries its own label, so a
    # URN written before the edition and volume segments existed still reads
    # back with both nil.
    class UrnParser < Pubid::UrnParser::Base
      def parse_urn(urn)
        parts = split_parts(strip_namespace(urn))
        tag = %w[tr mem].include?(parts.first) ? parts.shift : nil
        number = parts.shift
        part = shift_labelled(parts, "part-")
        edition = shift_labelled(parts, "ed-")
        volume = shift_labelled(parts, "vol-")
        flavor_parse(reconstruct(tag, number, part, edition, volume))
      end

      private

      # Consume the next segment only if it carries `label`. `delete_prefix`,
      # not `sub`, so a label-shaped substring later in the value is untouched.
      def shift_labelled(parts, label)
        return nil unless parts.first&.start_with?(label)

        parts.shift.delete_prefix(label)
      end

      # Rebuild the printed identifier string from the URN fields.
      def reconstruct(tag, number, part, edition, volume)
        base = case tag
               when "tr" then "ECMA TR/#{number}"
               when "mem" then "ECMA MEM/#{number}"
               else part ? "ECMA-#{number}-#{part}" : "ECMA-#{number}"
               end
        base += " ed#{edition}" if edition
        base += " vol#{volume}" if volume
        base
      end
    end
  end
end
