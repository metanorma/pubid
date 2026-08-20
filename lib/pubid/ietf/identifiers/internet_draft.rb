# frozen_string_literal: true

module Pubid
  module Ietf
    module Identifiers
      # An Internet-Draft, e.g. "draft-giuliano-treedn-02" (versioned) or
      # "draft-giuliano-treedn" (the unversioned "latest" sibling). The full
      # slug (including the leading "draft-") is stored in `number` — it is the
      # relaton-index narrowing key, shared by a draft's unversioned aggregator
      # row and all of its versions; the optional trailing two-digit version is
      # in `version`.
      class InternetDraft < Identifier
        include Serialization

        # Two-digit version string, zero-pad preserved ("02"); nil for the
        # unversioned "latest" sibling, in which case the canonical to_hash
        # drops the key entirely.
        attribute :version, :string

        # Merged with the block Serialization installs (lutaml combines a
        # mixin-installed key_value with a second in-class one), so the
        # serialized shape is {_type, number} plus `version` when set.
        key_value do
          map "version", to: :version
        end

        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :internet_draft,
            stage_code: :draft,
            type_code: :internet_draft,
            abbr: ["I-D", "Internet-Draft"],
            name: "Internet-Draft",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :internet_draft, web: :internet_draft,
            title: "Internet-Draft", short: "I-D" }
        end
      end
    end
  end
end
