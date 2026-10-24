# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ieee
    module Components
      # IEEE draft version
      # Handles formats like:
      #   /D5              - version only
      #   /D3.4            - version with revision
      #   /D7, July 2019   - with date
      class Draft < Lutaml::Model::Serializable
        include ::Pubid::SubsetMatch

        attribute :version, :string       # D5, D3, etc.
        attribute :revision, :string      # .4, .2 in D3.4
        attribute :year, :string
        attribute :month, :string
        attribute :day, :string
        attribute :original_month, :string # Store original month format
        attribute :comma_before_month, :boolean, default: -> {
          false
        } # Track if comma was in input
        # The joint stage-draft half of the compound form "D5=DDIS.3":
        # the ISO/IEC stage this draft iterates (DIS) and its iteration
        # numeral (3). See docs/IEEE-DRAFT-STAGES.md §1.3.
        attribute :iso_stage, :string
        attribute :iso_iteration, :string

        # Month name to number mapping
        MONTH_NAMES = {
          "January" => "1", "February" => "2", "March" => "3", "April" => "4",
          "May" => "5", "June" => "6", "July" => "7", "August" => "8",
          "September" => "9", "October" => "10", "November" => "11", "December" => "12",
          "Jan" => "1", "Feb" => "2", "Mar" => "3", "Apr" => "4",
          "Jun" => "6", "Jul" => "7", "Aug" => "8", "Sep" => "9", "Sept" => "9",
          "Oct" => "10", "Nov" => "11", "Dec" => "12"
        }.freeze

        def initialize(version: nil, revision: nil, year: nil, month: nil,
day: nil, iso_stage: nil, iso_iteration: nil)
          super()
          self.version = version
          self.revision = revision
          self.year = year
          # The canonical month form is the IEEE crawl abbreviation
          # (C2 ruling: "Aug 2007" and "August 2007" are the same
          # document, so the model normalizes and matches? unifies the
          # spellings; the long face spells the name back out).
          self.original_month = month && CANONICAL_ABBREVIATIONS[month.sub(/\.\z/, "")] || month
          self.month = convert_month(month)
          self.day = day
          # The grammar's ordered alternation captures the stage WITH its
          # draft-marker D when the spelling doubles it ("=DDIS"): the
          # marker is notation, the stage is the bare ISO/IEC token.
          if iso_stage.to_s.start_with?("D") &&
             %w[PWI NP WD CD CDV DIS FDIS].include?(iso_stage[1..])
            iso_stage = iso_stage[1..]
          end
          self.iso_stage = iso_stage
          self.iso_iteration = iso_iteration
        end

        # Canonical month spelling: the crawl abbreviation. Full names
        # normalize onto these ("August" → "Aug"); "September" keeps its
        # IEEE "Sept" form, so the 3-letter "Sep" folds onto it too.
        CANONICAL_ABBREVIATIONS = {
          "January" => "Jan", "February" => "Feb", "March" => "Mar",
          "April" => "Apr", "June" => "Jun", "July" => "Jul",
          "August" => "Aug", "September" => "Sept", "October" => "Oct",
          "November" => "Nov", "December" => "Dec", "Sep" => "Sept",
        }.freeze

        # Month names as an alternation, longest-first so "September" wins over
        # "Sep"; each may carry a trailing period ("Sept."). Used to split a
        # rendered draft's trailing date back out.
        MONTH_ALTERNATION =
          MONTH_NAMES.keys.sort_by { |m| -m.length }
            .map { |m| "#{Regexp.escape(m)}\\.?" }.join("|").freeze
        private_constant :MONTH_ALTERNATION

        DATE_SUFFIX =
          /(?:(, | )(#{MONTH_ALTERNATION})(?: (\d{1,2}))?(?:, | )|, | )((?:19|20)\d{2}[a-z]{0,2})\z/
        private_constant :DATE_SUFFIX

        # Parse a rendered draft such as "/D3", "/D3.4", "/D7 Jul 2019", or a
        # bare "D5"/"5" back into a Draft. This is the exact inverse of #to_s:
        # `Draft.parse(d.to_s).to_s == d.to_s` must hold, because the identifier
        # stores the draft as its rendered string and rebuilds the object with
        # this method after `from_hash` (a mismatch breaks `to_hash` round-trip).
        # @param value [String, Draft] the value to coerce
        # @return [Draft]
        # The compound stage suffix (docs/IEEE-DRAFT-STAGES.md §1.3):
        # "=DIS.3" is canonical — D (draft) = DIS (the stage), iteration 3.
        # "=DDIS.3", "=DDIS3", "=DDIS-3" (the stage echoed with its own D)
        # are accepted aliases. Captures [stage, iteration].
        COMPOUND_SUFFIX = /=D?(PWI|NP|WD|CDV|FDIS|DIS|CD)(?:[.-]?(\d+))?\z/.freeze
        private_constant :COMPOUND_SUFFIX

        # The D-echo aliases ("DDIS3" = D + DIS + iteration 3) normalize
        # through the compound split; every other pure stage token
        # ("CD1", "FCD", "CDV1") restores verbatim -- the compound split
        # would degrade the glued iterations and drop the stages the
        # alias list never knew, so from_hash(row) != parse(row).
        ECHO_SUFFIX = /\AD(=?(PWI|NP|WD|CDV|FDIS|DIS|CD|FCD))(?:[.-]?\d+)?\z/.freeze
        private_constant :ECHO_SUFFIX

        def self.parse(value)
          return value if value.is_a?(Draft)

          body = strip_prefix(value.to_s)
          iso_stage = nil
          iso_iteration = nil
          if body.start_with?("=") && body[1..].match?(/\A[A-Z][A-Z0-9]*\z/) &&
             !body[1..].match?(ECHO_SUFFIX)
            iso_stage = body[1..]
            body = ""
          elsif (m = body.match(COMPOUND_SUFFIX))
            iso_stage = m[1]
            iso_iteration = m[2]
            body = body[0...m.begin(0)]
          end
          # a designator that consumed the whole body carries no date;
          # split_date("") would leave version as "" where the parse
          # path has nil (and != compares them)
          version, month, day, year, comma = body.empty? ? [nil, nil, nil, nil, false] : split_date(body)
          draft = new(version: version, month: month, day: day, year: year,
                      iso_stage: iso_stage, iso_iteration: iso_iteration)
          draft.comma_before_month = comma
          draft
        end

        # Remove the leading "/D" (or a bare leading "D"/"/") that #to_s emits,
        # leaving the version and any trailing date.
        def self.strip_prefix(str)
          return str[2..] if str.start_with?("/D")
          return str[1..] if str.start_with?("/")
          return str[1..] if str.start_with?("D") && str.length > 1

          str
        end
        private_class_method :strip_prefix

        # Split a trailing rendered date off the version, so the version stays
        # clean (the SI/PSI renderer reads `draft_obj.version` directly). Returns
        # [version, month, day, year, comma_before_month].
        def self.split_date(body)
          m = body.match(DATE_SUFFIX)
          return [body, nil, nil, nil, false] unless m

          version = body[0...m.begin(0)]
          # The leading group is nil for the month-less " YEAR" form.
          comma = m[1] == ", "
          [version, m[2], m[3], m[4], comma]
        end
        private_class_method :split_date

        # Convert month name to numeric value
        def convert_month(month_name)
          return nil unless month_name

          MONTH_NAMES[month_name] || month_name
        end

        # Access the numeric month value
        def numeric_month
          month
        end

        def to_s
          result = "/D#{version}"
          result += "=#{iso_stage}" if iso_stage
          result += ".#{iso_iteration}" if iso_stage && iso_iteration
          result += if revision.to_s.start_with?(".")
                      # a captured revision may carry its separator dot
                      revision.to_s
                    else
                      ".#{revision}"
                    end if revision

          if year
            if iso_stage
              # The D= designator face dash-joins its date in IEEE's
              # convention: the year, and a draft month rides the
              # designator zero-padded ("D=FDIS-201008", pubid#203).
              result += "-#{year}"
              result += format("%02d", month.to_i) if month
              return result
            end

            # Use original month format to preserve abbreviated vs full names
            display_month = original_month

            if display_month
              # Use comma_before_month flag if set, otherwise detect from month format
              use_comma_before = if defined?(@comma_before_month) && !@comma_before_month.nil?
                                   @comma_before_month
                                 else
                                   # Default: Full month names have comma, abbreviated don't
                                   display_month.length > 4 && display_month != "Sept"
                                 end

              result += use_comma_before ? ", #{display_month}" : " #{display_month}"
              result += " #{day}" if day

              # Abbreviated months: " Year", Full months: ", Year"
              result += if display_month.length <= 4 || display_month == "Sept"
                          " #{year}"
                        else
                          ", #{year}"
                        end
            else
              # The year-only date joins with its comma - the grammar's
              # comma-year draft tail (pubid-grammar 17244fc) - so the
              # render re-parses through the same clause.
              result += ", #{year}"
            end
          end

          result
        end
      end
    end
  end
end
