# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Nist
    module Components
      # Supplement component for NIST publications
      # Represents supplement notation with number, year, month, or revision
      #
      # Examples:
      #   Supplement.new(number: "2").to_s(:short)              # => "sup2"
      #   Supplement.new(year: "1925").to_s(:short)              # => "sup1925"
      #   Supplement.new(number: "3", year: "1926").to_s(:short) # => "sup3/1926"
      #   Supplement.new(month: "Jan", year: "1924").to_s(:short) # => "supJan1924"
      #   Supplement.new(has_revision: true).to_s(:short)        # => "suprev"
      class Supplement < Lutaml::Model::Serializable
        attribute :number, :string           # Supplement number (e.g., "2" in "supp2")
        attribute :year, :string             # Year (4 digits); range START year
        attribute :month, :string            # Month abbreviation; range START month
        # Date ranges reuse :month/:year as the start and add the end below. A
        # present :month_end/:year_end is what marks a value as a range, so a
        # lone month-year supplement is just a range with no end — and :year is
        # the single field to filter on for both.
        attribute :month_end, :string         # Date range end month
        attribute :year_end, :string          # Date range end year
        attribute :has_revision, :boolean, default: -> {
          false
        } # "supprev" pattern
        attribute :suffix, :string # General suffix for other patterns

        # Build a Supplement from the flat string the parser/builder produces
        # ("1924" year, "Jan1924" month+year, "1" number, "A" suffix, "" bare).
        # has_revision is supplied separately. Returns a present-but-empty
        # Supplement for an empty/nil value so callers can distinguish a bare
        # supplement ("sup") from no supplement (nil).
        def self.from_raw(value, has_revision: false)
          supp = new
          if has_revision
            supp.has_revision = true
          elsif value.nil? || value.to_s.empty?
            # bare marker: present but no isolated parts
          elsif (m = value.to_s.match(/\A([A-Za-z]{3,9})(\d{4})\z/))
            supp.month = m[1]
            supp.year = m[2]
          elsif value.to_s.match?(/\A(?:18|19|20)\d{2}\z/)
            supp.year = value.to_s
          elsif value.to_s.match?(/\A\d+\z/)
            supp.number = value.to_s
          else
            supp.suffix = value.to_s
          end
          supp
        end

        # Render supplement in specified format
        # @param format [:short, :mr, :long] The output format
        # @return [String] The formatted supplement representation
        def to_s(format = :short)
          return "" if number.nil? && year.nil? && month.nil? && !has_revision &&
            suffix.nil? && month_end.nil? && year_end.nil?

          case format
          when :short, :mr
            build_short_format
          when :long
            build_long_format
          else
            build_short_format
          end
        end

        # True when this supplement is a date range (start reuses month/year).
        def range?
          date_range?
        end

        # The text after the "sup" marker for the simple (non-range, non-rev)
        # forms: "1924" / "Jan1924" / "1" / "A"; "" for a bare supplement. Used
        # by URN rendering, which handles range/revision separately.
        def value_string
          return "" if has_revision || date_range?
          return suffix.to_s if suffix
          return "#{month}#{year}" if month && year
          return "#{number}/#{year}" if number && year
          return year.to_s if year
          return number.to_s if number

          ""
        end

        # Value equality over the isolated parts, so a structured supplement
        # participates correctly in Identifier#== and #matches? (two supplements
        # with the same number/year/month/range/revision are the same).
        IDENTITY_FIELDS = %i[
          number year month month_end year_end has_revision suffix
        ].freeze

        def ==(other)
          return false unless other.is_a?(self.class)

          IDENTITY_FIELDS.all? { |f| public_send(f) == other.public_send(f) }
        end

        alias eql? ==

        def hash
          [self.class, *IDENTITY_FIELDS.map { |f| public_send(f) }].hash
        end

        private

        # Build short format: "sup2", "sup1925", "sup3/1926", "supJan1924", "suprev"
        # NIST/NBS canonical short form is single-p "sup" with the suffix
        # attached directly (relaton-data-nist uses "sup2", "sup1940", "supA").
        def build_short_format
          return "suprev" if has_revision
          return "sup#{suffix}" if suffix
          return build_date_range_format if date_range?
          return build_month_year_format if month && year
          return build_number_year_format if number && year
          return build_year_format if year
          return build_number_format if number

          ""
        end

        # Build long format: "Supplement 2", "Supplement 1925", etc.
        def build_long_format
          return "Supplement with Revision" if has_revision
          return "Supplement #{suffix}" if suffix
          return build_long_date_range_format if date_range?
          return build_long_month_year_format if month && year
          return build_long_number_year_format if number && year
          return build_long_year_format if year
          return build_long_number_format if number

          ""
        end

        # A range is marked by the presence of an END; START reuses month/year.
        # Months are optional, so a year-only range ("1925-1926") also counts.
        def date_range?
          year && year_end
        end

        def build_date_range_format
          "sup#{month}#{year}-#{month_end}#{year_end}"
        end

        def build_month_year_format
          "sup#{month}#{year}"
        end

        def build_number_year_format
          "sup#{number}/#{year}"
        end

        def build_year_format
          "sup#{year}"
        end

        def build_number_format
          "sup#{number}"
        end

        def build_long_date_range_format
          start = [month, year].compact.join(" ")
          finish = [month_end, year_end].compact.join(" ")
          "Supplement #{start}-#{finish}"
        end

        def build_long_month_year_format
          "Supplement #{month} #{year}"
        end

        def build_long_number_year_format
          "Supplement #{number}/#{year}"
        end

        def build_long_year_format
          "Supplement #{year}"
        end

        def build_long_number_format
          "Supplement #{number}"
        end
      end
    end
  end
end
