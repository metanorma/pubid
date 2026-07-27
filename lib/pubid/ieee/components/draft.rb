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
        attribute :version, :string       # D5, D3, etc.
        attribute :revision, :string      # .4, .2 in D3.4
        attribute :year, :string
        attribute :month, :string
        attribute :day, :string
        attribute :original_month, :string # Store original month format
        attribute :comma_before_month, :boolean, default: -> {
          false
        } # Track if comma was in input

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
day: nil)
          super()
          self.version = version
          self.revision = revision
          self.year = year
          self.original_month = month # Store original format
          self.month = convert_month(month)
          self.day = day
        end

        # Month names as an alternation, longest-first so "September" wins over
        # "Sep"; each may carry a trailing period ("Sept."). Used to split a
        # rendered draft's trailing date back out.
        MONTH_ALTERNATION =
          MONTH_NAMES.keys.sort_by { |m| -m.length }
            .map { |m| "#{Regexp.escape(m)}\\.?" }.join("|").freeze
        private_constant :MONTH_ALTERNATION

        DATE_SUFFIX =
          /(?:(, | )(#{MONTH_ALTERNATION})(?: (\d{1,2}))?(?:, | )| )((?:19|20)\d{2}[a-z]{0,2})\z/
        private_constant :DATE_SUFFIX

        # Parse a rendered draft such as "/D3", "/D3.4", "/D7 Jul 2019", or a
        # bare "D5"/"5" back into a Draft. This is the exact inverse of #to_s:
        # `Draft.parse(d.to_s).to_s == d.to_s` must hold, because the identifier
        # stores the draft as its rendered string and rebuilds the object with
        # this method after `from_hash` (a mismatch breaks `to_hash` round-trip).
        # @param value [String, Draft] the value to coerce
        # @return [Draft]
        def self.parse(value)
          return value if value.is_a?(Draft)

          body = strip_prefix(value.to_s)
          version, month, day, year, comma = split_date(body)
          draft = new(version: version, month: month, day: day, year: year)
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
          result += ".#{revision}" if revision

          if year
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
              result += " #{year}"
            end
          end

          result
        end
      end
    end
  end
end
