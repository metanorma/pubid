# frozen_string_literal: true

module Pubid
  module Iana
    # Human-readable renderer for IANA registry identifiers.
    #
    # Produces the authoritative printed form:
    #   "IANA _6lowpan-parameters"
    #   "IANA _6lowpan-parameters/lowpan_nhc"
    #
    # With `with_publisher: false` on the identifier it renders the bare
    # index-key slug instead (no "IANA " token).
    class Renderer < ::Pubid::Renderers::Base
      PUBLISHER = "IANA"

      def render(**_opts)
        id = @id
        # A stale (pre-`number`) row must not render as a bare "IANA " or
        # "IANA /lowpan_nhc"; see Identifier#require_number!.
        id.require_number!
        code = id.code
        with_publisher?(id) ? "#{PUBLISHER} #{code}" : code
      end

      private

      def with_publisher?(id)
        id.with_publisher != false
      end
    end
  end
end
