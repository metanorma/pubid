# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Bsi
    module Identifiers
      # Set represents multiple standards published as a set
      # Format: {identifier} + {identifier} [+ {identifier} ...]
      # Each identifier is separated by " + " (space, plus, space)
      #
      # Examples:
      #   BS ISO 20400 + BS ISO 44001+BS ISO 44002
      #   BS ISO 9001+BS ISO 14001
      class Set < SingleIdentifier
        attribute :identifiers, ::Pubid::Identifier, collection: true, 
                                                     polymorphic: true
        attribute :separators, :string, collection: true # Should all be " + "

        def <=>(other)
          return nil unless other.is_a?(Set)

          # Compare first identifier
          identifiers.first <=> other.identifiers.first
        end

        # As for BundledIdentifier: a set holds no number of its own, so walk
        # to the first member for the relaton-index key.
        #
        # NOTE the members are frequently a FOREIGN flavor (BS ISO ... holds
        # Pubid::Iso identifiers), which `to_hash` still rejects — see the
        # hand-off bsi-set-cross-flavor-type. `#root` is unaffected by that:
        # it only reads the object, never serializes it.
        def root
          identifiers&.first ? identifiers.first.root : self
        end
      end
    end
  end
end
