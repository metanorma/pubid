# frozen_string_literal: true

module Pubid
  module Tgpp
    # Emits `urn:3gpp:<type>:<code>:<release>:<version>`, e.g.
    # `urn:3gpp:ts:23.207:REL-4:2.0.0`. `<code>` is number+suffix+parts.
    #
    # A partial identifier has no release, no version, or neither. Only the
    # TRAILING empty segments are dropped, so a bare reference gets the clean
    # `urn:3gpp:ts:23.207` rather than a malformed `urn:3gpp:ts:23.207::`. An
    # INTERIOR empty segment is kept, so the release-less form keeps the URN it
    # has always emitted: `TS 29.215/2.0.0` -> `urn:3gpp:ts:29.215::2.0.0`.
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        (head_segments + tail_segments).join(":")
      end

      private

      # The namespace, the document type and the code. Always present.
      def head_segments
        ["urn", "3gpp", identifier.type_prefix.downcase, identifier.code]
      end

      # The two optional qualifiers, with the trailing empty ones removed.
      def tail_segments
        segments = [identifier.release, identifier.version]
        # NOTE: `empty?`, not `any?` — a bare `Array#any?` tests element
        # truthiness, so `[nil, nil].any?` is false and would strip nothing.
        segments.pop until segments.empty? || !blank?(segments.last)
        segments.map(&:to_s)
      end

      def blank?(value)
        value.nil? || value.empty?
      end
    end
  end
end
