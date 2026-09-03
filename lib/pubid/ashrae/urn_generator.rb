# frozen_string_literal: true

module Pubid
  module Ashrae
    class UrnGenerator < Pubid::UrnGenerator::Base
      # A supplement carries no number of its own — only the two
      # single-document leaves declare one — so reach it through #root, which
      # walks `base` to the standard the supplement attaches to. Without the
      # fallback every Errata/Addendum URN lost its number when `code` moved
      # off the shared base onto the leaves.
      def urn_number
        num = identifier.number || identifier.root.number
        return nil if num.nil? || num.to_s.empty?

        num.to_s
      end

      def urn_suffix
        identifier.suffix&.to_s&.downcase
      end

      def urn_amendment
        "amd.#{identifier.amendment}" if identifier.amendment
      end

      def urn_reaffirmed
        "reaff.#{identifier.reaffirmed}" if identifier.reaffirmed
      end

      def urn_copublisher
        "copub.#{identifier.copublisher.to_s.downcase}" if identifier.copublisher
      end

      def urn_addendum
        val = maybe(:addendum)
        "add.#{val}" if val
      end

      def generate
        parts = ["urn", "ashrae"]
        parts << urn_number if urn_number
        parts << urn_year if urn_year
        parts << identifier.type.to_s.downcase if identifier.type
        parts << urn_suffix if urn_suffix
        parts << urn_amendment if urn_amendment
        parts << urn_reaffirmed if urn_reaffirmed
        parts << urn_copublisher if urn_copublisher

        parts[1] = identifier.publisher.to_s.downcase if identifier.publisher

        parts << urn_addendum if urn_addendum

        parts.join(":")
      end
    end
  end
end
