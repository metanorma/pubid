# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Supplement identifier (Suppl.)
      # Pattern: "ITU-T H Suppl. 1", "ITU-T E.156 Suppl. 2"
      class Supplement < Identifier
        attribute :base, Identifier, polymorphic: true
        attribute :number, :string

        # Compact serialization: a supplement carries only its own ordinal
        # `number`, its own date, and the nested (itself-flat) `base`. type/code
        # are delegated to `base` and NOT re-emitted. sector/series are emitted
        # ONLY for the base-less, series-only form ("ITU-T H Suppl. 1"); when a
        # base is present they are redundant copies of the base's and suppressed.
        # Inherited unchanged by Amendment / Corrigendum / Errata.
        key_value do
          map "_type", to: :_type
          map "sector",
              with: { to: :supplement_sector_to_kv, from: :sector_from_kv }
          map "series",
              with: { to: :supplement_series_to_kv, from: :series_from_kv }
          map "number", to: :number
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

        def to_s
          result = base ? base.to_s : "#{publisher}-#{sector}"

          # Add series if no base
          if !base && series
            result += " #{series}"
          end

          result += " Suppl. #{number}"

          result += render_date_suffix

          result
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

          sector == other.sector && series == other.series
        end
      end
    end
  end
end
