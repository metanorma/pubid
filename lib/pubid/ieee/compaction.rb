# frozen_string_literal: true

module Pubid
  module Ieee
    # Serialization compaction for IEEE hashes — a recursive transform hooked
    # into Ieee::Identifier#to_hash (collapse) and .from_hash (expand). Two
    # compactions, both provably lossless and nested-safe (they descend into a
    # Corrigendum `base` too):
    #
    # 1. **typed_stage -> `stage` scalar.** The multi-field `typed_stage` object
    #    becomes a single `stage` key holding its canonical abbreviation,
    #    rebuilt from the TYPED_STAGES registry. The abbreviation keys the
    #    registry uniquely, and the collapse fires only when the registry's
    #    reconstruction is byte-identical to the serialized sub-hash — an
    #    unrecognised / non-matching stage is left as the full object (fails
    #    closed).
    #
    # 2. **`draft` slash strip.** `Components::Draft#to_s` renders `"/D3"`; the
    #    leading `/` is boilerplate, so the serialized form is `"D3"`. No expand
    #    step is needed — `Draft.parse` already accepts the slashless form and
    #    reproduces `"/D3"` (verified across the whole corpus), so from_hash and
    #    rendering are unchanged.
    #
    # A recursive hash transform (rather than lutaml attributes) is deliberate:
    # `stage` collides with the inherited `Components::Stage` attribute name (a
    # redefinition would reintroduce the multi-flavor nondeterminism we hit with
    # `number`), and only a whole-hash walk reaches a nested Corrigendum `base`,
    # which a per-object `to_hash` override cannot (the nested-serialization
    # wall). The runtime `typed_stage`/`draft_obj` objects are untouched.
    module Compaction
      module_function

      # abbr => canonical serialized typed_stage sub-hash, mirroring what the
      # parent serializer + canonicalizer emit (nils dropped, and a default
      # `project_status: false` dropped). Memoized.
      def sub_hash_for(abbr)
        (@sub_hash_for ||= build_sub_hash_map)[abbr]
      end

      def build_sub_hash_map
        TypedStages::TYPED_STAGES.to_h { |ts| [ts.abbr.first, entry_sub_hash(ts)] }
      end

      # NB: this must list every Components::TypedStage attribute. If a field is
      # added there but not here, the collapse guard fails closed — affected
      # stages stay full objects (still lossless) but stop compacting; extend
      # this list to keep them compact.
      def entry_sub_hash(typed_stage)
        {
          "abbr" => typed_stage.abbr,
          "stage_code" => typed_stage.stage_code,
          "type_code" => typed_stage.type_code,
          "iso_stage_equivalent" => typed_stage.iso_stage_equivalent,
          "ieee_draft_equivalent" => typed_stage.ieee_draft_equivalent,
          "approval_status" => typed_stage.approval_status,
          "project_status" => typed_stage.project_status || nil,
        }.compact
      end

      # Recursively compact every hash in the tree: collapse a reproducible
      # `typed_stage` to a `stage` scalar and strip the leading `/` off `draft`.
      def collapse(node)
        collapse_hash(node) if node.is_a?(::Hash)
        node.each { |v| collapse(v) } if node.is_a?(::Array)
        node
      end

      def collapse_hash(node)
        collapse_stage(node)
        draft = node["draft"]
        node["draft"] = draft.delete_prefix("/") if draft.is_a?(::String)
        node.each_value { |v| collapse(v) }
      end

      # Collapse only when the registry rebuilds the exact same sub-hash, so no
      # information is ever lost.
      def collapse_stage(node)
        ts = node["typed_stage"]
        abbr = ts["abbr"]&.first if ts.is_a?(::Hash)
        return unless abbr && sub_hash_for(abbr) == ts

        node.delete("typed_stage")
        node["stage"] = abbr
      end

      # Inverse of {collapse} for `stage`: replace a recognised `stage` scalar
      # with its registry typed_stage sub-hash so lutaml rebuilds the component
      # (nested bases included). `draft` needs no expansion — Draft.parse
      # accepts the slashless form. An unrecognised value is left alone.
      def expand(node)
        expand_hash(node) if node.is_a?(::Hash)
        node.each { |v| expand(v) } if node.is_a?(::Array)
        node
      end

      def expand_hash(node)
        key = stage_key(node)
        sub = sub_hash_for(node[key].to_s) if key
        if sub
          node.delete(key)
          node["typed_stage"] = deep_dup(sub)
        end
        node.each_value { |v| expand(v) }
      end

      def stage_key(node)
        return :stage if node.key?(:stage)

        "stage" if node.key?("stage")
      end

      def deep_dup(node)
        case node
        when ::Hash then node.transform_values { |v| deep_dup(v) }
        when ::Array then node.map { |v| deep_dup(v) }
        else node
        end
      end
    end
  end
end
