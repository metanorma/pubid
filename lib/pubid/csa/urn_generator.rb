# frozen_string_literal: true

module Pubid
  module Csa
    class UrnGenerator < Pubid::UrnGenerator::Base
      # A code_only identifier printed no publisher, so it keeps an empty
      # publisher segment rather than falling back to "csa" in #generate.
      def urn_publisher_prefix
        return "" if code_only?
        return nil unless identifier.publisher_prefix

        identifier.publisher_prefix.to_s.downcase
      end

      def code_only?
        identifier.respond_to?(:code_only) && identifier.code_only
      end

      def urn_number
        return nil unless identifier.number

        identifier.number.render(context: URN_CONTEXT)
      end

      def urn_no_number
        "no.#{identifier.no_number}" if identifier.no_number
      end

      def urn_series
        "series.#{identifier.series}" if identifier.series
      end

      def urn_series_prefix
        "series.#{identifier.series_prefix}" if identifier.series_prefix
      end

      def urn_year_csa
        return nil unless identifier.year

        year = identifier.year.to_s
        year = year[-2..] if year.length == 4 && year.start_with?("20")
        year
      end

      def urn_reaffirmation
        "reaff.#{identifier.reaffirmation}" if identifier.reaffirmation
      end

      def urn_package
        "pkg.#{identifier.package}" if identifier.package
      end

      def urn_year_format
        "format.dash" if identifier.year_format == "dash"
      end

      def urn_french
        "french" if identifier.french
      end

      def generate
        parts = ["urn", "csa"]

        prefix = urn_publisher_prefix || "csa"
        parts << prefix

        parts << urn_number if urn_number
        parts << urn_no_number if urn_no_number
        parts << urn_series if urn_series
        parts << urn_series_prefix if urn_series_prefix

        year = urn_year_csa
        if year
          year = "#{identifier.year_prefix}#{year}" if identifier.year_prefix
          parts << year
        end

        parts << urn_reaffirmation if urn_reaffirmation
        parts << urn_package if urn_package
        parts << urn_year_format if urn_year_format
        parts << urn_french if urn_french

        parts.join(":")
      end
    end
  end
end
