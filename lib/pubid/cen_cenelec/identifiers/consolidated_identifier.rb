# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # Consolidated Identifier - base document plus supplements.
      # "EN 196-3:2005+A1:2008" = [EN 196-3:2005, Amendment(base + params)]
      class ConsolidatedIdentifier < Base
        # Members span both flavor chains: SingleIdentifier documents (EN,
        # the base document) and Identifiers::Base supplements (Amendment).
        # The flavor handle is their common root - the type lutaml enforces
        # at serialization. Polymorphic _type routing covers both.
        attribute :identifiers, Pubid::CenCenelec::Identifier,
                  polymorphic: true, collection: true

        # Delegate to first identifier (base document)
        def publisher
          identifiers&.first&.publisher
        end

        def number
          identifiers&.first&.number
        end

        def year
          identifiers&.first&.year
        end

        # Members are polymorphic and mixed-chain: SingleIdentifier-chain
        # documents (EN, the usual first member) declare no +parts+ - the
        # part of "EN 196-3" lives in the member's own number - while
        # Identifiers::Base descendants (Amendment, ...) carry the
        # attribute. Delegate only when the member has it; a part-less
        # base document has no parts to expose.
        def parts
          first = identifiers&.first
          first.parts unless first.is_a?(SingleIdentifier)
        end

        def type
          identifiers&.first&.type
        end

        # The origin document. Members live in `identifiers` (not `base`), so
        # walk the first member to its root.
        def root
          identifiers&.first&.root || self
        end
      end
    end
  end
end
