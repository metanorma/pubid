# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # A labelled appendix of a Recommendation — "ITU-T G.101 App. I
      # (05/2000)", "ITU-T G.722 (1988) App. IV (11/2006)".
      #
      # Structurally the twin of AnnexOfRecommendation: an appendix is
      # published and dated separately from the Recommendation it appends, and
      # may itself carry an amendment/errata ("ITU-T G.729 App. I (2002)
      # Amd. 1"). The label is a Roman numeral rather than a series letter.
      class AppendixOfRecommendation < Identifier
        attribute :base, Identifier, polymorphic: true
        # The appendix label ("I", "II", "IV"). Named `number` for symmetry
        # with Supplement's ordinal and AnnexOfRecommendation's label; it
        # shadows Identifier#number (code&.number), which is nil here anyway —
        # the document number is reached via #root.
        attribute :number, :string
        # The companion artefact published under the appendix's designation:
        # "test vectors" or "Software". Its own catalogue record, so it must
        # stay distinct from the appendix itself.
        attribute :material, :string

        # Compact serialization: the nested (itself-flat) base plus this
        # document's own label, date and language. sector/series/code belong to
        # the base and are deliberately not re-emitted.
        key_value do
          map "_type", to: :_type
          map "number", to: :number
          map "material", to: :material
          map "year", with: { to: :year_to_kv, from: :year_from_kv }
          map "month", with: { to: :month_to_kv, from: :month_from_kv }
          map "base", with: { to: :base_to_kv, from: :base_from_kv }
          map "language", to: :language
          map "common_text_twin",
              with: { to: :common_text_twin_to_kv,
                      from: :common_text_twin_from_kv }
        end

        # "<base urn>:appendix:<label>[:<date>]" — the appendix's own date must
        # be there, or two editions of one appendix share a URN (the base's
        # date rides inside base_urn, so omitting this one would be asymmetric).
        def to_urn
          segments = [base&.to_urn || "urn:itu", "appendix", number&.downcase]
          # Without this the test-vector record and the appendix itself would
          # share a URN.
          segments << material.downcase.gsub(/[^a-z0-9]/, "") if material
          segments << urn_date_segment
          segments.compact.join(":")
        end

        def render_base(**opts)
          result = base ? base.render_base(**opts) : "#{publisher}-#{sector}"

          result += " App. #{number}"
          result += " #{material}" if material
          result + render_date_suffix
        end

        # MR: recurse into the appendixed document and append
        # "app.<label>[.year]" (the documented supplement-suffix hook), so the
        # slug stays distinct per appendix. Without it the wrapper's own nil
        # sector/series/code would collapse every appendix onto "itu.<year>".
        def mr_supplement_suffix
          label = "#{number}#{material}".downcase.gsub(/[^a-z0-9]/, "")

          ["app", label.empty? ? nil : label, date&.year].compact.join(".")
        end

        def ==(other)
          return false unless other.instance_of?(self.class)

          base == other.base &&
            number == other.number &&
            material == other.material &&
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
