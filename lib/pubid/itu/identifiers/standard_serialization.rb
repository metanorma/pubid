# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Installs the compact flat `key_value` block shared by the "single
      # document" leaf types (Recommendation, Handbook, SpecialPublication, and
      # — extended with their own extra maps — Question and CombinedIdentifier).
      #
      # The block lives on the leaves rather than the shared Identifier because
      # the delegating subtypes (Supplement/Annex) would otherwise inherit-and-
      # merge it and re-emit their `base`'s fields (the ETSI lesson). The
      # converter methods it references are defined once on Pubid::Itu::Identifier.
      module StandardSerialization
        def self.included(base)
          base.key_value do
            map "_type", to: :_type
            map "sector",
                with: { to: :sector_to_kv, from: :sector_from_kv }
            map "series",
                with: { to: :series_to_kv, from: :series_from_kv }
            map "imp_marker",
                with: { to: :imp_marker_to_kv, from: :imp_marker_from_kv }
            map "number",
                with: { to: :number_to_kv, from: :number_from_kv }
            map "series_suffix",
                with: { to: :series_suffix_to_kv, from: :series_suffix_from_kv }
            map "subseries",
                with: { to: :subseries_to_kv, from: :subseries_from_kv }
            map "parts",
                with: { to: :parts_to_kv, from: :parts_from_kv }
            map "version", to: :version
            map "year",
                with: { to: :year_to_kv, from: :year_from_kv }
            map "month",
                with: { to: :month_to_kv, from: :month_from_kv }
            map "language", to: :language
            map "common_text_twin",
                with: { to: :common_text_twin_to_kv,
                        from: :common_text_twin_from_kv }
          end
        end
      end
    end
  end
end
