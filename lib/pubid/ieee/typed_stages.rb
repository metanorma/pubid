# frozen_string_literal: true

module Pubid
  module Ieee
    # Registry of all IEEE typed stages
    # Single source of truth for stage/type combinations
    #
    # IEEE has three approval levels:
    # 1. Unapproved Draft (D1-D6): Working drafts
    # 2. Approved Draft (D7-D9): Board-approved but unpublished
    # 3. Published: Final standards (no P prefix, no D number)
    #
    # For joint development with ISO/IEC, both IEEE and ISO stages may appear
    module TypedStages
      TYPED_STAGES = [
        # Published Standards (no P prefix, no draft notation)
        Components::TypedStage.new(
          abbr: ["Std"],
          stage_code: "published",
          type_code: "standard",
          approval_status: "published",
          project_status: false,
        ),

        # IEEE Draft Stages (P prefix, unapproved)
        # D1 - Initial working draft
        Components::TypedStage.new(
          abbr: ["D1"],
          stage_code: "working_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D1",
          iso_stage_equivalent: "WD",
          approval_status: "unapproved",
          project_status: true,
        ),

        # D2, D3 - Committee draft stages
        Components::TypedStage.new(
          abbr: ["D2", "D3"],
          stage_code: "committee_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D2-D3",
          iso_stage_equivalent: "CD",
          approval_status: "unapproved",
          project_status: true,
        ),

        # D4, D5, D6 - Draft standard stages
        Components::TypedStage.new(
          abbr: ["D4", "D5", "D6"],
          stage_code: "draft_standard",
          type_code: "draft",
          ieee_draft_equivalent: "D4-D6",
          iso_stage_equivalent: "DIS",
          approval_status: "unapproved",
          project_status: true,
        ),

        # IEEE Draft Stages (P prefix, approved but unpublished)
        # D7, D8, D9 - Final draft (board-approved)
        Components::TypedStage.new(
          abbr: ["D7", "D8", "D9"],
          stage_code: "final_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D7-D9",
          iso_stage_equivalent: "FDIS",
          approval_status: "approved",
          project_status: true,
        ),

        # ISO Stages (for joint development with ISO/IEC/IEEE)
        # These stages appear in joint development identifiers
        Components::TypedStage.new(
          abbr: ["PWI"],
          stage_code: "preliminary",
          type_code: "draft",
          ieee_draft_equivalent: "P",
          iso_stage_equivalent: "PWI",
          approval_status: "unapproved",
          project_status: true,
        ),

        Components::TypedStage.new(
          abbr: ["NP"],
          stage_code: "new_proposal",
          type_code: "draft",
          ieee_draft_equivalent: "P",
          iso_stage_equivalent: "NP",
          approval_status: "unapproved",
          project_status: true,
        ),

        Components::TypedStage.new(
          abbr: ["WD"],
          stage_code: "working_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D1",
          iso_stage_equivalent: "WD",
          approval_status: "unapproved",
          project_status: true,
        ),

        Components::TypedStage.new(
          abbr: ["CD", "CD1", "CD2", "CD3", "CD4"],
          stage_code: "committee_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D2-D3",
          iso_stage_equivalent: "CD",
          approval_status: "unapproved",
          project_status: true,
        ),

        # Committee Draft for Vote (IEC/ISO-led historical stage)
        Components::TypedStage.new(
          abbr: ["CDV"],
          stage_code: "committee_draft_for_vote",
          type_code: "draft",
          ieee_draft_equivalent: "D2-D3",
          iso_stage_equivalent: "CDV",
          approval_status: "unapproved",
          project_status: true,
        ),

        Components::TypedStage.new(
          abbr: ["DIS"],
          stage_code: "draft_international_standard",
          type_code: "draft",
          ieee_draft_equivalent: "D5",
          iso_stage_equivalent: "DIS",
          approval_status: "unapproved",
          project_status: true,
        ),

        Components::TypedStage.new(
          abbr: ["FDIS"],
          stage_code: "final_draft",
          type_code: "draft",
          ieee_draft_equivalent: "D8",
          iso_stage_equivalent: "FDIS",
          approval_status: "approved",
          project_status: true,
        ),

        # Historical stages (AIEE, IRE)
        # "No" or "No." for AIEE standards
        Components::TypedStage.new(
          abbr: ["No", "No."],
          stage_code: "published",
          type_code: "standard",
          approval_status: "published",
          project_status: false,
        ),

        # Generic "P" prefix for drafts (when specific D number not known)
        Components::TypedStage.new(
          abbr: ["P"],
          stage_code: "draft",
          type_code: "draft",
          ieee_draft_equivalent: "P",
          approval_status: "unapproved",
          project_status: true,
        ),

        # Draft without specific version (legacy)
        Components::TypedStage.new(
          abbr: ["Draft"],
          stage_code: "draft",
          type_code: "draft",
          approval_status: "unapproved",
          project_status: true,
        ),
      ].freeze

      # Default typed stage for published standards
      DEFAULT_TYPED_STAGE = TYPED_STAGES.first
    end

    # Backward compatibility aliases at module level
    # These allow code expecting Pubid::Ieee::TYPED_STAGES to still work
    TYPED_STAGES = TypedStages::TYPED_STAGES
    DEFAULT_TYPED_STAGE = TypedStages::DEFAULT_TYPED_STAGE
  end
end
