# frozen_string_literal: true

module Pubid
  module Iana
    # Emits `urn:iana:<registry>[:<sub_registry>]`. Slugs contain no ":"
    # (charset is [a-zA-Z0-9._-]), so the two levels split unambiguously.
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        # A stale (pre-`number`) row would otherwise emit the bare "urn:iana:"
        # for every affected id; see Identifier#require_number!.
        identifier.require_number!
        # `number` holds the top-level registry slug (Identifiers::Registry).
        parts = ["urn", "iana", identifier.number]
        parts << identifier.sub_registry if identifier.sub_registry
        parts.join(":")
      end
    end
  end
end
