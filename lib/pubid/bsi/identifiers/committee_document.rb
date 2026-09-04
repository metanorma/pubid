# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # CommitteeDocument represents BSI committee draft documents
      # Format: YY/NNNNNNNN DC (2-digit year, 8-digit number, DC suffix)
      #
      # Examples:
      #   14/30300822 DC
      #   21/30445138 DC
      #   24/30300822 DC
      class CommitteeDocument < SingleIdentifier
        # The 8-digit document number lives in the `number` inherited from
        # SingleIdentifier (a Bsi::Components::Code). It used to be a separate
        # `document_number` :string, which left `number` nil — so `root.number`,
        # the key relaton-index sorts and bsearches on, was "".
        #
        # The duplicate is DELETED rather than mirrored into `number`: keeping
        # both would emit the same digits twice in `to_hash`, and a derived
        # `#number` method is not available here because `number` is a lutaml
        # attribute, whose generated accessor such a method would collide with.
        # Nothing is retyped — the inherited attribute is already a Code.

        # TYPED_STAGES for committee documents (draft by default)
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :draft_committee,
            stage_code: :draft,
            type_code: :committee_document,
            abbr: ["DC"],
            name: "Draft Committee Document",
            harmonized_stages: %w[30.00 30.20 30.60 40.00 40.20 40.60],
          ),
        ].freeze

        def self.type
          { key: :committee_document, title: "Committee Document", short: "DC" }
        end

      end
    end
  end
end
