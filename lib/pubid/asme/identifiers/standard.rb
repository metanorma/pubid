# frozen_string_literal: true

module Pubid
  module Asme
    module Identifiers
      class Standard < Base
        # --- Index columns -------------------------------------------------
        #
        # relaton-index sorts and bsearches every row on
        # `id.root.number.to_s`. ASME used to keep the code inside an
        # Asme::Components::Code under a `code` attribute, leaving the
        # inherited `number` nil and every row keyed "".
        #
        # `number` holds the WHOLE printed code — "B18.3", "A112.19.12",
        # "BPVC-CC-BPV" — not a designator/number split.
        #
        # The split looks tempting (it is what IEEE does) but it cannot key
        # this corpus: 152 of the 731 fixture ids are Boiler and Pressure
        # Vessel Code documents whose entire identity IS the designator
        # ("BPVC COMPLETE CODE BIND", "BPVC.CC.BPV") with no numeric part at
        # all. Splitting leaves every one of them with an empty key, and
        # inventing a number for them would be inventing data.
        #
        # Nothing is lost by joining: Components::Code#render is a plain
        # concatenation of designator and number, and the only readers of
        # `code` anywhere in lib/pubid/asme are `code.to_s` (renderer.rb,
        # urn_generator.rb). Keying on the whole code also clusters editions of
        # one document, which is what relaton narrows on — an ASME reference is
        # always written "ASME B18.3", never "18.3" alone.
        #
        # LANDMINE: `number` redefines the Components::Code attribute inherited
        # from ::Pubid::Identifier, which resolves nondeterministically when
        # declared on a class others inherit from. Standard is the only
        # concrete ASME type and has no subclasses, so it is declared here and
        # never on SingleIdentifier / Identifiers::Base.
        # spec/pubid/asme/root_number_spec.rb carries the tripwire and is only
        # meaningful under the full `rake` suite.
        # There is deliberately no `#code` reader here. An earlier draft had one
        # composing `Components::Code.new(number: number)` so the renderer and
        # the URN generator would not have to change — but because `number`
        # holds the whole printed code, that Code never carried a designator and
        # `code.to_s` equalled `number` for all 731 corpus ids. It wrapped a
        # string in an object whose only job was to unwrap to the same string.
        # Both readers now use `number` directly.
        #
        # ASTM keeps its composed `#code` (Identifiers::CodeNumber) for the
        # opposite reason: its renderer reads `code.letter` / `code.dual_m`
        # field-by-field, so the component there carries real structure.
        attribute :number, :string

        # MR slug. Before the index column landed, every ASME slug was just
        # "asme": 722 of 731 documents shared one filename, and `to_slug` is
        # what consumers use as an output filename.
        #
        # `handbook` is identity-bearing — it is in the serialized hash and in
        # `==`, and "ASME A17.1/CSA B44-2019" and "ASME A17.1/CSA B44
        # Handbook-2019" are different documents — so it has to reach the slug
        # too. CLAUDE.md's rule: a marker that only reaches `==` still lets two
        # documents share a filename.
        def mr_number_with_part
          mr_join(mr_sanitize(number), (handbook ? "handbook" : nil))
        end

        # ASME keeps its edition in a plain `year` string, not the inherited
        # `date`, so the base `mr_year` hook read nil and every edition of one
        # standard shared a slug.
        def mr_year
          year&.to_s
        end

        # ASME keeps a translation marker in a plain `language` string, not the
        # inherited `languages` collection the base hook reads. Without this,
        # "ASME B31.8-2016" and its Spanish edition "ASME B31.8 (SPANISH)-2016"
        # — different documents, and #== agrees — share one filename.
        def mr_languages
          language&.to_s&.downcase
        end

        # An ASME code legitimately contains "." (B18.3), "-" (BPVC-CC-BPV),
        # "&" (V&V) and spaces ("BPVC COMPLETE CODE BIND"). Renderers::MrString
        # joins SEGMENTS with ".", so a dot inside one breaks that structure —
        # filter by charset, the BIPM `mr_slug` precedent, rather than by an
        # enumerated escape list. The output emptiness check matters: a value
        # made only of out-of-charset characters collapses to "", which is
        # truthy in Ruby and would reach the renderer as a blank segment.
        def mr_sanitize(value)
          return nil if value.nil? || value.to_s.empty?

          sanitized = value.to_s.downcase
            .gsub(/[^a-z0-9-]+/, "-").gsub(/\A-+|-+\z/, "")
          sanitized.empty? ? nil : sanitized
        end
      end
    end
  end
end
