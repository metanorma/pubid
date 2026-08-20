# frozen_string_literal: true

module Pubid
  module Ietf
    # Parses IETF URNs back into identifiers by reconstructing the printed form
    # and delegating to the flavor's text parser. Inverts UrnGenerator:
    #   urn:ietf:rfc:2119                     -> "RFC 2119"
    #   urn:ietf:bcp:3                        -> "BCP 3"
    #   urn:ietf:id:draft-giuliano-treedn:02  -> "draft-giuliano-treedn-02"
    #   urn:ietf:id:draft-giuliano-treedn     -> "draft-giuliano-treedn"
    class UrnParser < Pubid::UrnParser::Base
      def parse_urn(urn)
        parts = split_parts(strip_namespace(urn))
        flavor_parse(human_text(parts.shift, parts))
      end

      private

      def human_text(type, parts)
        case type
        when "rfc" then "RFC #{parts[0]}"
        when "bcp", "std", "fyi" then "#{type.upcase} #{parts[0]}"
        when "id" then draft_text(parts)
        else invalid_type!(type)
        end
      end

      # `Errors` is defined under Pubid::UrnParser (the module), which is
      # neither in this class's lexical scope nor an ancestor of Base, so the
      # constant must be fully qualified — a bare `Errors::ParseError` raises
      # NameError instead of the intended error.
      def invalid_type!(type)
        raise Pubid::UrnParser::Errors::ParseError,
              "Invalid IETF URN type: #{type.inspect}"
      end

      def draft_text(parts)
        name, version = parts
        version ? "#{name}-#{version}" : name
      end
    end
  end
end
