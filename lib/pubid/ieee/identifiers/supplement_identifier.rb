# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Identifier class for supplement identifiers (amendments, corrigenda, interpretations, etc.)
      # Supplements modify or add to a base document
      class SupplementIdentifier < Identifier
        attribute :base, Identifier, polymorphic: true

        # Delegate publisher to base
        def publisher
          base&.publisher
        end

        # Delegate code to base if not overridden
        def code
          base&.code
        end

        # `publisher` is a pure delegation to `base`, so it must never be
        # serialized independently on the wrapper. lutaml's default-tracking
        # otherwise emits it asymmetrically — omitted on the parse path (the
        # wrapper's own attribute is never assigned) but present after
        # `from_hash` (deserialization assigns it) — which breaks the canonical
        # `to_hash` round-trip for a supplement whose base carries a non-default
        # publisher (e.g. an ANSI/ISO corrigendum). The truth lives in `base`.
        def to_hash(*args)
          hash = super
          if hash.is_a?(::Hash)
            # `publisher` and `code` are delegated to `base`; never serialize
            # them on the wrapper (they'd duplicate base.publisher/base.number
            # and, for publisher, desync across parse vs from_hash).
            hash.delete("publisher")
            hash.delete("code")
          end
          hash
        end
      end
    end
  end
end
