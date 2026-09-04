# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Multi-Numbered Identifier
      # Represents a single document published under multiple numbers
      # Examples:
      # - "IEEE Std 1299/C62.22.1-1996" (same document, two numbers)
      # - "IEEE Std 960-1989, Std 1177-1989" (same document, two numbers)
      class MultiNumberedIdentifier < Identifier
        # Both designations are real lutaml attributes.
        #
        # They used to be `attr_accessor`s, which lutaml cannot see — so
        # `to_hash` emitted {"_type" => "pubid:ieee:multi-numbered-identifier"}
        # and NOTHING else, `from_hash` could not rebuild either member, and
        # `#exclude` (which iterates self.class.attributes) skipped them. The
        # whole identity was dropped. That is the CSA container defect recorded
        # in CLAUDE.md, and the fix is the same: make the members attributes.
        #
        # The type is the CROSS-FLAVOR ::Pubid::Identifier, not IEEE's own:
        # `polymorphic: true` widens only to subclasses, and the second
        # designation may belong to another body — the same reason
        # AdoptedStandard's members carry that type.
        attribute :primary_identifier, ::Pubid::Identifier, polymorphic: true
        attribute :secondary_identifier, ::Pubid::Identifier, polymorphic: true

        # One document under two numbers, neither of them held here, so
        # `root.number` was "". Walk to the primary designation.
        def root
          primary_identifier ? primary_identifier.root : self
        end

        # Carry the number onto the URN and the MR slug as well as #root — see
        # AdoptedStandard#code_obj.
        def code_obj
          primary_identifier&.code_obj
        end

        # See AdoptedStandard#mr_year. `year` below already delegates, so this
        # only stringifies — it is kept explicit so the hook survives if that
        # delegation is ever removed in favour of the URN generator's
        # `year_component` root fallback.
        def mr_year
          year&.to_s
        end

        def publisher
          primary_identifier&.publisher
        end

        def code
          primary_identifier&.code
        end

        def year
          primary_identifier&.year
        end

        # `publisher` and `year` are DERIVED from primary_identifier — and,
        # since that member became a serialized attribute above, the derived
        # values are now re-emitted after from_hash materializes the attribute
        # defaults, while the parse path omits them as unset. That asymmetry
        # breaks `from_hash(to_hash) == to_hash`, the gate relaton's index
        # build uses to decide whether to keep a document.
        #
        # It is latent rather than live for the one corpus id (its primary is
        # IEEE-published with no year, so both derived values match their
        # defaults and are dropped anyway), but the class documents that its
        # members may belong to another body — and a synthetic AIEE primary
        # reproduces it immediately. Dropping the keys is lossless:
        # primary_identifier rebuilds both. Same treatment as
        # AdoptedStandard#to_hash and DualPublished#to_hash.
        def to_hash(*args)
          hash = super
          return hash unless hash.is_a?(::Hash)

          hash.delete("publisher")
          hash.delete("year")
          hash
        end
      end
    end
  end
end
