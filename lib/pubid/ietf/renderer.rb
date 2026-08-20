# frozen_string_literal: true

module Pubid
  module Ietf
    # Human-readable renderer for IETF identifiers.
    #
    # Produces strings like:
    #   "RFC 2119"
    #   "BCP 3" / "STD 66" / "FYI 1"
    #   "draft-giuliano-treedn-02" / "draft-giuliano-treedn"
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **_opts)
        require_number!(@id)
        render_identifier(@id)
      end

      private

      # For an Internet-Draft, `number` holds the version-less slug including
      # the leading "draft-"; for the sub-series, `series` is derived from the
      # class rather than stored. The sub-series arm names its three classes
      # explicitly instead of being a catch-all `else`, because a bare
      # Pubid::Ietf::Identifier has no `series` reader at all.
      def render_identifier(id)
        case id
        when Identifiers::Rfc then "RFC #{id.number}"
        when Identifiers::InternetDraft then render_draft(id)
        when Identifiers::Bcp, Identifiers::Std, Identifiers::Fyi
          "#{id.series} #{id.number}"
        else unsupported!(id)
        end
      end

      def render_draft(id)
        id.version ? "#{id.number}-#{id.version}" : id.number
      end

      # Fail loudly rather than render a nil/partial string. `number` carries
      # the whole document identity for every IETF type, so a nil one means the
      # object was built from something that is not a current IETF hash — most
      # likely a pre-`number` index row, which stored an Internet-Draft slug
      # under `name` (a key nothing reads any more; lutaml ignores it
      # silently). Such a row would otherwise deserialize into an identifier
      # that renders "" or "-02" and keys the index under "", with no error
      # anywhere — exactly the silent-wrong-lookup failure this flavor's
      # round-trip specs exist to prevent. Regenerate the
      # relaton-data-{rfcs,rfcsubseries,ids} indexes instead.
      def require_number!(id)
        return unless id.respond_to?(:number)
        return unless id.number.nil? || id.number.empty?

        raise ArgumentError,
              "Cannot render #{id.class} with an empty number " \
              "(a pre-`number` index row stored the draft slug under `name`; " \
              "regenerate the index)"
      end

      def unsupported!(id)
        raise ArgumentError,
              "Cannot render #{id.class}: not a concrete IETF identifier"
      end
    end
  end
end
