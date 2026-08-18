# frozen_string_literal: true

module Pubid
  module Schema
    # Loads and validates flavor declarations from schema/. Declarations
    # are memoized and deeply frozen; loading is lazy per flavor so the
    # parse hot path pays no boot cost.
    class Loader
      SCHEMA_ROOT = File.expand_path("../../../schema", __dir__).freeze
      CORE_DIR = File.join(SCHEMA_ROOT, "core").freeze

      class << self
        def for(flavor)
          flavor = flavor.to_s
          declarations[flavor] ||= build_declaration(flavor)
        end

        def joint_prefixes_for(flavor)
          joint_prefixes[flavor.to_s] || [].freeze
        end

        # Full joint-prefix map (flavor key => tokens) from
        # schema/core/joint_prefixes.yaml.
        def joint_prefixes_map
          joint_prefixes
        end

        def loaded_flavors
          declarations.keys.sort
        end

        private

        def declarations
          @declarations ||= {}
        end

        def joint_prefixes
          @joint_prefixes ||= load_joint_prefixes
        end

        def load_joint_prefixes
          path = File.join(CORE_DIR, "joint_prefixes.yaml")
          data = YAML.safe_load_file(path)
          data.fetch("joint_prefixes")
            .transform_values(&:freeze)
            .freeze
        rescue Errno::ENOENT, KeyError => e
          raise InvalidError, "cannot load #{path}: #{e.message}"
        end

        def build_declaration(flavor)
          path = declaration_path(flavor)
          data = YAML.safe_load_file(path)
          validate!(flavor, path, data)
          Declaration.new(
            flavor: data.fetch("flavor"),
            schema_version: data.fetch("schema_version"),
            prefixes: data.fetch("prefixes"),
            identifier_types: parse_identifier_types(data),
          ).freeze
        end

        def declaration_path(flavor)
          path = File.join(SCHEMA_ROOT, "#{flavor}.yaml")
          unless File.exist?(path)
            raise NotFoundError, "no declaration for #{flavor} at #{path}"
          end

          path
        end

        def parse_identifier_types(data)
          data.fetch("identifier_types")
            .map { |entry| parse_identifier_type(entry) }
        end

        def parse_identifier_type(entry)
          IdentifierType.new(
            key: entry.fetch("key"),
            title: entry.fetch("title"),
            short: entry["short"],
            abbr: entry["abbr"] || [],
            typed_stages: parse_typed_stages(entry),
          )
        end

        def parse_typed_stages(entry)
          (entry["typed_stages"] || []).map { |stage| parse_typed_stage(stage) }
        end

        def parse_typed_stage(stage)
          TypedStage.new(
            stage_code: stage.fetch("stage_code"),
            type_code: stage["type_code"],
            abbr: stage.fetch("abbr"),
            name: stage["name"],
            harmonized_stages: stage["harmonized_stages"] || [],
          )
        end

        def validate!(flavor, path, data)
          raise InvalidError, "#{path}: not a mapping" unless data.is_a?(Hash)

          %w[flavor schema_version prefixes identifier_types].each do |key|
            next if data.key?(key)

            raise InvalidError, "#{path}: missing required key #{key}"
          end
          return unless data["flavor"] != flavor

          raise InvalidError, "#{path}: flavor/file mismatch"
        end
      end
    end
  end
end
