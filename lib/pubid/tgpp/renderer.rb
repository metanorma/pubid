# frozen_string_literal: true

module Pubid
  module Tgpp
    # Human-readable renderer for 3GPP identifiers.
    #
    # Produces strings like:
    #   "TS 23.207:REL-4/2.0.0"                (default, no publisher)
    #   "3GPP TS 23.207:REL-4/2.0.0"           (with_publisher: true)
    #   "TS 29.198-04-1:REL-5/5.0.0"           (parts)
    #   "TR 00.01U:UMTS/3.0.0"                 (suffix)
    #   "TS 23.207"                            (partial reference)
    class Renderer < ::Pubid::Renderers::Base
      PUBLISHER = "3GPP"

      def render(context: nil, **_opts)
        id = @id
        head = []
        head << PUBLISHER if with_publisher?(id)
        head << id.type_prefix
        "#{head.join(' ')} #{id.code}#{qualifiers(id)}"
      end

      private

      # The trailing ":<release>" and "/<version>" qualifiers. Both are
      # optional: a handful of legacy records omit the release entirely
      # (e.g. "TS 29.215/2.0.0"), and a partial user reference omits both
      # (e.g. "TS 23.207"). Render no separator for an absent one.
      #
      # Blank, not just nil: the grammar cannot produce "", but a hand-built
      # hash can, and a dangling "TS 23.207:" would not re-parse. This mirrors
      # the same guard in UrnGenerator#tail_segments.
      def qualifiers(id)
        result = +""
        result << ":#{id.release}" unless blank?(id.release)
        result << "/#{id.version}" unless blank?(id.version)
        result
      end

      def blank?(value)
        value.nil? || value.empty?
      end

      # Default is no publisher token (the relaton index id form); the caller
      # opts in via `to_s(with_publisher: true)`.
      def with_publisher?(id)
        id.with_publisher == true
      end
    end
  end
end
