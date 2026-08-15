# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Supplement identifier (Suppl.)
      # Pattern: "ITU-T H Suppl. 1", "ITU-T E.156 Suppl. 2"
      class Supplement < Identifier
        attribute :base, Identifier, polymorphic: true
        attribute :number, :string

        # Rendering-only flags for spellings ITU itself uses. Both name the
        # RARE form so the `false` default is stripped from `to_hash` and no
        # existing serialized row gains a key.
        #
        # `number_glued` — no space before the ordinal ("ITU-T E Suppl.1",
        # "ITU-T D.211 Suppl.1"). Deliberately NOT part of `==`: "Suppl.1" and
        # "Suppl. 1" are the same document.
        #
        # `slash_joined` — joined to the preceding supplement by "/" instead of
        # a space ("ITU-T X.680 (1994) Amd. 1/Technical Cor. 1 (12/1997)").
        attribute :number_glued, :boolean, default: -> { false }
        attribute :slash_joined, :boolean, default: -> { false }

        # Compact serialization: a supplement carries only its own ordinal
        # `number`, its own date, and the nested (itself-flat) `base`. type/code
        # are delegated to `base` and NOT re-emitted. sector/series are emitted
        # ONLY for the base-less, series-only form ("ITU-T H Suppl. 1"); when a
        # base is present they are redundant copies of the base's and are
        # suppressed. Inherited by Amendment / Corrigendum / Errata / Addendum,
        # of which only Corrigendum adds a key of its own.
        key_value do
          map "_type", to: :_type
          map "sector",
              with: { to: :supplement_sector_to_kv, from: :sector_from_kv }
          map "series",
              with: { to: :supplement_series_to_kv, from: :series_from_kv }
          map "series_word",
              with: { to: :supplement_series_word_to_kv,
                      from: :series_word_from_kv }
          map "number", to: :number
          map "number_glued", to: :number_glued
          map "slash_joined", to: :slash_joined
          map "year", with: { to: :year_to_kv, from: :year_from_kv }
          map "month", with: { to: :month_to_kv, from: :month_from_kv }
          map "base", with: { to: :base_to_kv, from: :base_from_kv }
          map "common_text_twin",
              with: { to: :common_text_twin_to_kv,
                      from: :common_text_twin_from_kv }
        end

        def supplement_sector_to_kv(model, doc)
          return unless model.base.nil?

          emit_kv(doc, "sector", model.sector&.sector)
        end

        def supplement_series_to_kv(model, doc)
          return unless model.base.nil?

          emit_kv(doc, "series", model.series&.series)
        end

        # Like sector/series above: the series group's "series" word is part of
        # the base-less form's identity only. With a base it belongs to (and is
        # serialized by) the base.
        def supplement_series_word_to_kv(model, doc)
          return unless model.base.nil?
          return unless model.series_word

          doc["series_word"] = true
        end

        def series_word_from_kv(model, value)
          model.series_word = value
        end

        # A supplement carries no `mr_supplement_suffix`, so the shared MR
        # renderer slugs it FLAT, from the sector/series/code Builder#build_
        # supplement copied up from its base — which never consults the base's
        # class. Without this, the supplement of a Report and the supplement of
        # the same-numbered Recommendation produce one slug (and `to_slug` is an
        # output filename, so one overwrites the other) — exactly the collision
        # this type exists to prevent. `root` walks through an intervening annex
        # or appendix, so a supplement of an annex of a Report is covered too.
        def mr_type
          type = super
          return type unless root.is_a?(Report)

          [type, "report"].compact.join(".")
        end

        # Shared by every supplement type — Suppl./Amd./Cor./Err./Add. differ
        # only in the label, so each subclass supplies its own and nothing else.
        #
        # `label` is the canonical spelling with its period; the parser also
        # accepts the period-less input (see Parser#supplement_type), which
        # normalizes here.
        def render_supplement(label)
          result = base ? base.to_s : "#{publisher}-#{sector}"

          # Add series if no base
          if !base && series
            result += " #{series}"
            result += " series" if series_word
          end

          result += slash_joined ? "/" : " "
          result += label
          result += " " unless number_glued
          result += number.to_s

          result += render_date_suffix

          result
        end

        def to_s
          render_supplement("Suppl.")
        end

        # Shared by Amendment / Corrigendum / Errata.
        #
        # `instance_of?` (not `is_a?`) so a Suppl. never equals an Amd./Cor./
        # Err. with the same ordinal, and so the comparison stays symmetric —
        # with `is_a?` a Supplement accepted an Amendment but not the reverse.
        #
        # sector/series are compared ONLY for the base-less, series-only form
        # ("ITU-T A Suppl. 2"), where they are the document's whole identity.
        # When a base is present they are copies of the base's (set by
        # Builder#build_supplement) and are deliberately not serialized (see
        # supplement_sector_to_kv), so comparing them would make a parsed
        # identifier unequal to the same identifier rebuilt via from_hash.
        def ==(other)
          return false unless other.instance_of?(self.class)

          return false unless base == other.base &&
            number == other.number &&
            date == other.date

          return true if base

          sector == other.sector && series == other.series &&
            series_word == other.series_word
        end
      end
    end
  end
end
