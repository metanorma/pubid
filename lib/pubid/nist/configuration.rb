# frozen_string_literal: true

require "yaml"

module Pubid
  module Nist
    # Configuration class responsible for loading and managing series definitions
    # Single Responsibility: Series configuration management
    class Configuration
      attr_reader :series

      def initialize(series_file_path = nil)
        @series_file_path = series_file_path || default_series_path
        load_series
      end

      # Get series long name
      # @param series_code [String] the series code (e.g., "SP", "FIPS")
      # @return [String, nil] the long name or nil if not found
      def series_long_name(series_code)
        @series.dig("long", series_code)
      end

      # Get series abbreviation
      # @param series_code [String] the series code
      # @return [String, nil] the abbreviation or nil if not found
      def series_abbrev(series_code)
        @series.dig("abbrev", series_code)
      end

      # Get series MR (machine-readable) format
      # @param series_code [String] the series code
      # @return [String, nil] the MR format or nil if not found
      def series_mr(series_code)
        @series.dig("mr", series_code)
      end

      # Check if series code is valid
      # @param series_code [String] the series code
      # @return [Boolean] true if series is valid
      def valid_series?(series_code)
        @series["long"].key?(series_code)
      end

      # Get all series codes
      # @return [Array<String>] all valid series codes
      def all_series_codes
        @series["long"].keys
      end

      # Get series code from MR format
      # @param mr_format [String] the MR format
      # @return [String, nil] the series code or nil if not found
      def series_from_mr(mr_format)
        @series["mr"].key(mr_format)
      end

      private

      def default_series_path
        # Prefer data/nist/series.yaml (the canonical home in the monorepo);
        # fall back to archived-gems/pubid-nist/series.yaml for backward
        # compat with the v1 layout.
        monorepo = File.join(__dir__, "../../../data/nist/series.yaml")
        return monorepo if File.exist?(monorepo)

        File.join(__dir__, "../../../archived-gems/pubid-nist/series.yaml")
      end

      def load_series
        @series = YAML.load_file(@series_file_path)
      rescue Errno::ENOENT
        raise ConfigurationError,
              "Series configuration file not found: #{@series_file_path}"
      rescue Psych::SyntaxError => e
        raise ConfigurationError,
              "Invalid YAML in series configuration: #{e.message}"
      end
    end

    class ConfigurationError < StandardError; end
  end
end
