# frozen_string_literal: true

module Pubid
  module Iana
    module Identifiers
      # The sole IANA identifier type: a protocol registry (optionally with a
      # sub-registry). Its class name yields the polymorphic `_type` tag
      # "pubid:iana:registry".
      #
      # Examples:
      #   IANA _6lowpan-parameters
      #   IANA _6lowpan-parameters/lowpan_nhc
      class Registry < Identifier
        # The top-level registry slug ("_6lowpan-parameters"), and the index
        # key: relaton-index bsearches on `id.root.number.to_s`, and every IANA
        # identifier is its own root (the flavor has no wrapper or supplement
        # types), so an empty key silently defeats the search for every row.
        #
        # An IANA identifier carries no numeric document number — digits only
        # ever appear glued inside a slug token (`sip-parameters-13`,
        # `idna-tables-11.0.0`), never as a separable component — so the slug
        # itself is the key, exactly as an Internet-Draft's slug is
        # (lib/pubid/ietf/identifiers/serialization.rb). Keying on the TOP-LEVEL
        # slug rather than the full `registry/sub_registry` code means a
        # registry and all of its sub-registries cluster into one bucket, the
        # analogue of a draft clustering with its versions.
        #
        # WHY THIS IS DECLARED HERE AND NOT ON Pubid::Iana::Identifier:
        # it redefines the parent ::Pubid::Identifier's
        # `attribute :number, Components::Code` as a plain :string. Declaring
        # that on a class the concrete type INHERITS from resolves against the
        # parent definition nondeterministically under multi-flavor load — it
        # passes an IANA-only run and can flip `root.number` to "" under the
        # full suite (the IEEE/IETF lesson; see
        # lib/pubid/ieee/identifiers/code_number.rb and CLAUDE.md). Declaring it
        # directly on the leaf removes the ambiguity at the point of use.
        # For the same reason, never define a `#number` *method* — it would
        # collide with lutaml's generated accessor.
        # spec/pubid/iana/root_number_spec.rb guards this and must run under the
        # FULL suite to be meaningful.
        attribute :number, :string

        # Merged by lutaml with the base's key_value block, which maps `_type`
        # and `sub_registry`. `registry` is deliberately NOT stored — it is the
        # same string as `number`, and the base exposes it as a derived reader.
        key_value do
          map "number", to: :number
        end

        # IANA registries carry no revision/stage lifecycle; a single published
        # typed stage keeps parity with the other flavors' type registries.
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pubiana,
            stage_code: :published,
            type_code: :iana,
            abbr: ["IANA"],
            name: "IANA Registry",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :iana, web: :registry, title: "IANA Registry", short: "IANA" }
        end
      end
    end
  end
end
