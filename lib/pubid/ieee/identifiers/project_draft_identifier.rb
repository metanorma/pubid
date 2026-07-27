# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Project Draft Identifier
      # Format: "IEEE P1234/D5, July 2019"
      # where P1234 is the project number and D5 is the draft version
      # This is distinct from a StandardIdentifier - the "P" indicates project status,
      # not a code prefix like "C" in "C57.12"
      class ProjectDraftIdentifier < Identifier
        # Reliable string `number` for relaton's index key (see CodeNumber).
        # Its #initialize `super` chains through CodeNumber, which sets `number`
        # from the (P-stripped) code after the parent builds code_obj.
        include CodeNumber

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["P"],
            stage_code: "draft",
            type_code: "draft",
            ieee_draft_equivalent: "P",
            approval_status: "unapproved",
            project_status: true,
          ),
        ].freeze

        def self.type
          { key: :P, title: "Project Draft", short: "P" }
        end

        # Override initialize to strip "P" prefix from code before creating Code
        # object. The "P" is reflected in the typed_stage, not in the Code
        # component itself. Accepts keyword args or a single positional hash (the
        # base #exclude/matching rebuild passes the latter).
        def initialize(args = {}, **kwargs)
          args = kwargs.empty? ? args.dup : args.merge(kwargs)
          # If code is provided with "P" prefix (e.g., "P1234"), strip it
          if args[:code].is_a?(String) && args[:code].start_with?("P")
            args[:code] = args[:code][1..] # Strip leading "P"
          end

          # Call parent initialize with modified code (positional hash)
          super(args)
        end
      end
    end
  end
end
