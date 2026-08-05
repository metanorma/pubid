# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Adopted Standard Identifier
      # IEEE's adoption of another organization's standard
      # Example: "IEEE Standard No 18-1968 (ANSI C55.1-1968)"
      # This means IEEE adopted ANSI's standard C55.1-1968 as their Std No 18-1968
      class AdoptedStandard < Identifier
        # IEEE's identifier for this adopted standard
        attribute :ieee_identifier, Identifier, polymorphic: true

        # Original identifiers from ANSI/ISO/IEC/etc (array for multi-part adoptions)
        attribute :adopted_identifiers, Identifier, polymorphic: true,
                                              collection: true

        def publisher
          ieee_identifier&.publisher || "IEEE"
        end

        # `publisher` is *derived* from `ieee_identifier` (the serialized source
        # of truth), so it must not be serialized. Emitting it breaks the
        # canonical round-trip: the derived value is default-omitted on the parse
        # path (publisher unset), but re-emitted after from_hash materializes the
        # attribute default (the override then returns ieee_identifier.publisher,
        # e.g. "AIEE", not the "IEEE" default). Drop it — ieee_identifier rebuilds
        # it. (AdoptedStandard is always a top-level wrapper, never nested, so a
        # to_hash-level drop is sufficient — same as JointDevelopment.)
        def to_hash(*args)
          hash = super
          hash.delete("publisher") if hash.is_a?(::Hash)
          hash
        end
      end
    end
  end
end
