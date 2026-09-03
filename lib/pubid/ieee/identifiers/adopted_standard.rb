# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Adopted Standard Identifier
      # IEEE's adoption of another organization's standard
      # Example: "IEEE Standard No 18-1968 (ANSI C55.1-1968)"
      # This means IEEE adopted ANSI's standard C55.1-1968 as their Std No 18-1968
      class AdoptedStandard < Identifier
        # IEEE's identifier for this adopted standard.
        #
        # Typed as the cross-flavor base `::Pubid::Identifier` (not the
        # IEEE-only `Identifier`) so serialization never rejects a cross-flavor
        # value. lutaml enforces the declared attribute type; `polymorphic:
        # true` permits only *subclasses* of it, and a `Pubid::Ansi::…` /
        # `Pubid::Iec::…` object is not a subclass of `Pubid::Ieee::Identifier`.
        # The cross-flavor child carries its own `_type`, so `from_hash` routes
        # it back via `TypeResolver`.
        attribute :ieee_identifier, ::Pubid::Identifier, polymorphic: true

        # Original identifiers from ANSI/ASME/ISO/IEC/etc (array for multi-part
        # adoptions). Cross-flavor by design: an `IEEE Std <n> (ANSI <m>)`
        # adoption stores a `Pubid::Ansi::…` object here. See `ieee_identifier`
        # above for why this must be `::Pubid::Identifier`, not IEEE-only.
        attribute :adopted_identifiers, ::Pubid::Identifier, polymorphic: true,
                                              collection: true

        def publisher
          ieee_identifier&.publisher || "IEEE"
        end

        # An adoption names one document by two designations and carries no
        # number of its own, so `root.number` — the key relaton-index sorts and
        # bsearches on — was "". Walk to the IEEE designation, which is the one
        # IEEE files the document under, and which is also the source of truth
        # for `publisher` above.
        def root
          ieee_identifier ? ieee_identifier.root : self
        end

        # The document number must reach the URN and the MR slug too, not only
        # `#root` — the project rule that an identity-bearing marker reaches
        # every identity surface. `UrnGenerator#code_component` and the base
        # `mr_number_with_part` both read `code_obj`, which a wrapper does not
        # have, so all 66 adoptions collapsed onto 5 URNs and 5 slugs — and
        # `to_slug` is an output FILENAME, so that is 66 documents overwriting
        # each other. Delegate to the IEEE designation, as `#root` does.
        #
        # `code_obj` is a plain attr_accessor on the base, not a lutaml
        # attribute, so overriding it as a method is safe here.
        def code_obj
          ieee_identifier&.code_obj
        end

        # Likewise the year: without it "AIEE No 15-1944" and "AIEE No 15-1959"
        # — two different documents — produced the same slug "aiee.std.15".
        # This is the `mr_year` HOOK, not a `#year` method: `year` is a lutaml
        # attribute on the base, and a method of that name would shadow the
        # generated accessor (the CLAUDE.md landmine).
        def mr_year
          (year || ieee_identifier&.year)&.to_s
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
