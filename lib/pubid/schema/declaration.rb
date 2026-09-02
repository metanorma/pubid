# frozen_string_literal: true

module Pubid
  module Schema
    # A loaded flavor declaration (schema/{flavor}.yaml).
    class Declaration
      attr_reader :flavor, :schema_version, :prefixes, :identifier_types

      def initialize(flavor:, schema_version:, prefixes:, identifier_types:)
        @flavor = flavor
        @schema_version = schema_version
        @prefixes = prefixes.freeze
        @identifier_types = identifier_types.map(&:freeze).freeze
        freeze
      end

      # Own tokens plus joint/co-publication tokens from
      # schema/core/joint_prefixes.yaml - mirrors the runtime
      # Pubid::{Flavor}.prefixes contract (see PrefixesSupport).
      def merged_prefixes
        (prefixes + Loader.joint_prefixes_for(flavor)).freeze
      end

      def type_for(key)
        identifier_types.find { |type| type.key == key }
      end

      def types_count
        identifier_types.size
      end
    end
  end
end
