# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      # OIML Bulletin issues and articles. Carries no code — the locator is
      # the (year, issue, sequence) tuple drawn from the issue's place in the
      # periodical hierarchy.
      #
      # Two input forms are accepted, both referring to the same article:
      #
      #   structured:  "OIML Bulletin 2026-02-11"
      #   citation:    "OIML Bulletin LXVII(2) 20260211"
      #
      # The structured form is the dataset's primary docid (sortable,
      # deterministic). The citation form is what OIML prints on the article
      # page (`Citation: AUTHOR YEAR OIML Bulletin VOLUME(ISSUE) ARTID`).
      #
      # Volume tracks year deterministically: 1960 = I, year - 1959 = volume.
      # The 8-digit article id is YYYYNNSS — the same three values concatenated,
      # so the citation form is decoded entirely from the article id; the
      # roman volume and parenthesised issue are redundant display.
      #
      # Shapes in relaton-data-oiml:
      #   "OIML Bulletin"                       (periodical)
      #   "OIML Bulletin 1960"                  (volume / year)
      #   "OIML Bulletin 1960-03"               (issue)
      #   "OIML Bulletin 1960-03-01"            (article, structured)
      #   "OIML Bulletin LXVII(2) 20260211"     (article, citation)
      class Bulletin < SingleIdentifier
        # OIML Bulletin volume I was issued in 1960. Volume N corresponds to
        # year (N + BASE_YEAR_OFFSET). Used to translate between the year
        # carried in the structured form and the roman volume in citations.
        BASE_YEAR_OFFSET = 1959

        # Zero-padded issue number within the year ("01".."04", plus "07"/"10"
        # for the online-bulletin series). Always 2 digits.
        attribute :issue, :string
        # Zero-padded sequence within the issue ("00" = editorial, "01"+ for
        # articles). Always 2 digits.
        attribute :sequence, :string

        key_value do
          map "issue", to: :issue
          map "sequence", to: :sequence
        end

        # relaton-index keys on `id.root.number.to_s`. Bulletin is the one OIML
        # leaf with no code (it does not include Identifiers::CodeNumber), so
        # it derives the key from the year it already stores: every issue and
        # article of a volume clusters into one bucket, with per-article
        # distinctness coming from the MR slug instead. That is the BIPM
        # Metrologia-volume precedent recorded in CLAUDE.md.
        #
        # A DERIVED READER, deliberately not an attribute: storing it would
        # duplicate `year` in every row, and the key_value block above maps no
        # "number", so nothing is added to the wire format. Safe as a plain
        # method because Bulletin declares no `number` attribute of its own
        # (the ITU itu/identifiers/base.rb precedent).
        #
        # nil for the bare periodical reference "OIML Bulletin", which names no
        # year — a deliberate gap, pinned in spec/pubid/oiml/root_number_spec.rb.
        def number
          date&.year&.to_s
        end

        # The index key above is deliberately coarse — a whole volume in one
        # bucket — which is only defensible because the MR slug stays
        # per-article. The inherited hook reads through `code`, which Bulletin
        # does not have, so it would return nil and collapse every article of a
        # year onto `oiml.bulletin.<year>`; `to_slug` is an output FILENAME, so
        # that is an overwrite. Emit the rest of the locator instead.
        #
        # The year is deliberately NOT included: Renderers::MrString already
        # gives it its own segment (`mr_year`), so repeating it here would
        # render `oiml.bulletin.1960-03-01.1960`.
        def mr_number_with_part
          segments = [issue, sequence].compact
          return nil if segments.empty?

          segments.join("-")
        end

        def type_string
          "Bulletin"
        end

        # Volume as an arabic string ("67"), derived from the year. nil when
        # the year is absent (bare periodical reference).
        def volume_arabic
          return nil unless date&.year

          (date.year.to_i - BASE_YEAR_OFFSET).to_s
        end

        # Volume as a roman-numeral string ("LXVII"), derived from the year.
        # nil when the year is absent.
        def volume_roman
          number = volume_arabic&.to_i
          return nil unless number&.positive?

          self.class.to_roman(number)
        end

        # 8-digit oiml.org article id ("20260211"). Composed by concatenating
        # year + issue + sequence. nil unless all three are present.
        def article_id
          return nil unless date&.year && issue && sequence

          "#{date.year}#{issue}#{sequence}"
        end

        class << self
          # Convert a positive integer to its roman-numeral representation.
          # Used to render the citation form. The dataset already stores the
          # roman volume verbatim in `extent.locality`, so this conversion is
          # only needed when rendering from the structured form.
          def to_roman(number)
            raise ArgumentError, "volume must be > 0" unless number.positive?

            ROMAN_TABLE.each_with_object(+"") do |(value, sym), result|
              quotient, number = number.divmod(value)
              result << (sym * quotient)
            end.freeze
          end

          ROMAN_TABLE = [
            [1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
            [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
            [10, "X"], [9, "IX"], [5, "V"], [4, "IV"],
            [1, "I"]
          ].freeze
        end
      end
    end
  end
end
