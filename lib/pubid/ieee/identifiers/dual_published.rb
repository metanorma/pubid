# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Dual Published Identifier
      # Document jointly published by two organizations
      # Example: "ANSI C37.61-1973 and IEEE Std 321-1973"
      # This means the document was published together by both organizations
      class DualPublished < Identifier
        # First organization's identifier
        attribute :first_identifier, Identifier, polymorphic: true

        # Second organization's identifier
        attribute :second_identifier, Identifier, polymorphic: true

        def publisher
          # Return array of both publishers
          [first_identifier&.publisher, second_identifier&.publisher].compact
        end

        # `publisher` above is DERIVED from the two member identifiers (the
        # serialized source of truth), so it must not be serialized itself.
        # Emitting it breaks the canonical round-trip exactly as it did on
        # Identifiers::AdoptedStandard and Identifiers::JointDevelopment: the
        # derived value is default-omitted on the parse path (the attribute is
        # unset), but re-emitted once from_hash materializes the attribute
        # default, because the override then returns the members' publishers
        # rather than the "IEEE" default. Worse here, it is an ARRAY, so the
        # re-emitted value was the literal string `["IEEE", "IEEE"]`.
        #
        # This made all 25 DualPublished ids in the fixture corpus fail
        # `from_hash(to_hash) == to_hash` — the gate relaton's index build
        # uses, which SKIPS a document that fails it. Dropping the key is
        # lossless: first_identifier and second_identifier rebuild it.
        #
        # A top-level to_hash delete is sufficient because DualPublished is
        # only ever a top-level wrapper, never a nested `base` (where lutaml's
        # own transform would bypass this override).
        def to_hash(*args)
          hash = super
          hash.delete("publisher") if hash.is_a?(::Hash)
          hash
        end

        # A dual-published document is one document under two designations, and
        # this wrapper carries neither number itself — so `root.number`, the key
        # relaton-index sorts and bsearches on, was "". Walk to the first
        # designation, which is the one the printed reference leads with.
        def root
          first_identifier ? first_identifier.root : self
        end

        # Carry the number onto the URN and the MR slug as well as #root — see
        # AdoptedStandard#code_obj for why all three surfaces need it.
        def code_obj
          first_identifier&.code_obj
        end

        # See AdoptedStandard#mr_year — without it the 1989 and the 1993
        # printings of "IEEE Std 960 and IEEE Std 1177" shared one slug.
        def mr_year
          (year || first_identifier&.year)&.to_s
        end

        # `#publisher` above returns an ARRAY, and the inherited `mr_publisher`
        # is `publisher&.to_s&.downcase` — so the MR slug contained a literal
        # Ruby array (`["ieee", "asme"]`, brackets, quotes, comma and space
        # included) and `to_slug` is an output FILENAME. Join the two instead,
        # keeping both publishers in the slug: they are equally part of this
        # document's identity, so by the project rule both must reach it.
        def mr_publisher
          names = Array(publisher).map { |p| p.to_s.downcase }.reject(&:empty?)
          names.empty? ? nil : names.join("-")
        end
      end
    end
  end
end
