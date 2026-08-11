# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # A labelled annex of a Recommendation — "ITU-T A.23 Annex A (06/2014)",
      # "ITU-T Z.100 Annex F3 (10/2019)", "ITU-T G.729 Annex C+ (02/2000)".
      #
      # The annex is a document in its own right: it is published (and dated)
      # separately from the Recommendation it annexes, and may itself carry a
      # corrigendum/errata/amendment ("ITU-T G.729 Annex B (1996) Cor. 3
      # (03/2001)").
      #
      # Distinct from Identifiers::Annex, which models the label-less
      # "Annex to ITU OB No. 1000" form (a prefix rendering with its own i18n
      # templates). Keeping them apart keeps each `_type` — already persisted in
      # relaton index rows — unambiguous.
      class AnnexOfRecommendation < Identifier
        attribute :base, Identifier, polymorphic: true
        # The annex label ("A", "F3", "C+"). Named `number` for symmetry with
        # Supplement's ordinal; it shadows Identifier#number (code&.number),
        # which is nil here anyway — the document number is reached via #root.
        attribute :number, :string

        # Compact serialization: the annex is the nested (itself-flat) base plus
        # its own label, date and language. sector/series/code are the base's
        # and are deliberately not re-emitted (the wrapper lesson).
        key_value do
          map "_type", to: :_type
          map "number", to: :number
          map "year", with: { to: :year_to_kv, from: :year_from_kv }
          map "month", with: { to: :month_to_kv, from: :month_from_kv }
          map "base", with: { to: :base_to_kv, from: :base_from_kv }
          map "language", to: :language
          map "common_text_twin",
              with: { to: :common_text_twin_to_kv,
                      from: :common_text_twin_from_kv }
        end

        # "<base urn>:annex:<label>[:<date>]" — the annex's own date must be
        # there, or two editions of one annex share a URN (the base's date
        # rides inside base_urn, so omitting the annex's would be asymmetric).
        def to_urn
          segments = [base&.to_urn || "urn:itu", "annex", number&.downcase]
          segments << urn_date_segment
          segments.compact.join(":")
        end

        def render_base(**opts)
          result = base ? base.render_base(**opts) : "#{publisher}-#{sector}"

          "#{result} Annex #{number}#{render_date_suffix}"
        end

        # MR: recurse into the annexed document and append "annex.<label>[.year]"
        # (the documented supplement-suffix hook), so the slug stays distinct
        # per annex. Without it the wrapper's own nil sector/series/code would
        # collapse every annex onto a bare "itu.<year>".
        def mr_supplement_suffix
          # "C+" -> "cplus", not "c" — the MR charset excludes "+", and
          # dropping it would collide with the sibling "Annex C".
          label = number.to_s.downcase.gsub("+", "plus").gsub(/[^a-z0-9]/, "")

          ["annex", label.empty? ? nil : label, date&.year].compact.join(".")
        end

        def ==(other)
          return false unless other.instance_of?(self.class)

          base == other.base &&
            number == other.number &&
            date == other.date &&
            language == other.language &&
            common_text_twin == other.common_text_twin
        end

        private

        def urn_date_segment
          return nil unless date

          date.month ? "#{date.month}/#{date.year}" : date.year.to_s
        end
      end
    end
  end
end
