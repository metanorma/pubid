# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      # Installs the flat, index-friendly code columns and their serialization
      # on the seven concrete OIML document leaves (Recommendation, Document,
      # Vocabulary, Guide, BasicPublication, ExpertReport, SeminarReport).
      #
      # Why the leaves and not Pubid::Oiml::SingleIdentifier, which they all
      # inherit from: `number` redefines the parent ::Pubid::Identifier's
      # `attribute :number, Components::Code` as a plain :string (and `part` /
      # `subpart` likewise). Declaring that on a class the concrete types
      # INHERIT from resolves against the parent definition nondeterministically
      # under multi-flavor load — it passes an OIML-only run and can flip
      # `root.number` to "" under the full suite (the IEEE lesson; see
      # lib/pubid/ieee/identifiers/code_number.rb and CLAUDE.md). Declaring on
      # each leaf removes the ambiguity at the point of use.
      #
      # This matters because relaton-index sorts and bsearches every row on
      # `id.root.number.to_s`. OIML kept the code in an Oiml::Components::Code
      # under a `code` attribute and never set `number`, so all 12,226 lines of
      # the published relaton-data-oiml index-v2 keyed "".
      #
      # The serialized hash ALREADY had these as bare top-level scalars — the
      # old converters merely read them through `code` — so the wire format is
      # byte-identical and that index needs no regeneration.
      #
      # Bulletin deliberately does NOT include this module. It carries no code
      # at all (its locator is the year/issue/sequence tuple), so it would only
      # gain a permanently-nil `number` and a `number` key that never appears.
      # It derives its index key from the year instead; see bulletin.rb.
      module CodeNumber
        def self.included(base)
          install_attributes(base)
          install_mappings(base)
        end

        def self.install_attributes(base)
          # Bare document number ("144"), the relaton index key. The part is a
          # sibling column, never folded in, so every part of a document shares
          # one bucket and a part-less reference finds them all.
          base.attribute :number, :string
          base.attribute :part, :string
          base.attribute :subpart, :string
          # Free-form trailing suffix glued to the code, e.g. "sup", "A",
          # "erratum", "GUM 1", "ISO3930". Preserved verbatim for round-trip.
          base.attribute :suffix, :string
          # When true the suffix is space-separated ("D 1 Brochure") rather
          # than the default dash ("R 60-sup"). Named for the RARE case with a
          # false default, so the canonical to_hash drops it from every
          # ordinary row.
          base.attribute :space_suffix, :boolean, default: -> { false }
        end

        # Merged by lutaml with the block SingleIdentifier declares, which
        # carries publisher/year/edition/stage/iteration.
        def self.install_mappings(base)
          base.key_value do
            map "number", to: :number
            map "part", to: :part
            map "subpart", to: :subpart
            map "suffix", to: :suffix
            map "space_suffix", to: :space_suffix
          end
        end

        # The composed document code, rebuilt on demand from the split columns
        # so the renderer and the URN generator keep one place to ask for the
        # printed form ("144-1", "60-sup"). Deliberately NOT an attribute and
        # NOT memoised: the columns are writable (the base #exclude rebuilds
        # through them), so a cached Code would go stale.
        #
        # nil when there is no number, preserving the old nil-`code` semantics
        # the URN generator branches on.
        def code
          return nil if number.nil?

          Components::Code.new(
            number: number,
            part: part,
            subpart: subpart,
            suffix: suffix,
            space_suffix: space_suffix,
          )
        end
      end
    end
  end
end
