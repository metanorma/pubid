# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # Standalone Amendment identifier (no base reference)
      # Examples: "AMD 11015", "(AMD 10971)", "AMD Corrigendum 14716"
      class StandaloneAmendment < SingleIdentifier
        # The amendment number lives in the `number` inherited from
        # SingleIdentifier — already a Bsi::Components::Code, exactly what the
        # deleted `amendment_number` was, so nothing is retyped. It used to sit
        # under the private name, leaving `number` nil and `root.number` "".
        #
        # A standalone amendment is its OWN document (there is no base standard
        # to walk to — that is what "standalone" means), so it needs a real
        # number rather than a #root override. `Identifiers::Amendment`, the
        # attached kind, keeps its own `amendment_number` and is untouched:
        # there the ordinal is a supplement ordinal, not the document number.
        attribute :corrigendum, :boolean, default: false
        attribute :parenthesized, :boolean, default: false

        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :standalone_amendment,
            stage_code: :published,
            type_code: :amendment,
            abbr: ["AMD"],
            name: "Amendment",
            harmonized_stages: %w[60.00 60.60],
          ),
        ].freeze

        def self.type
          { key: :standalone_amendment, title: "Amendment", short: "AMD" }
        end

      end
    end
  end
end
