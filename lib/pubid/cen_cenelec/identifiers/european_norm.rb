# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # European Norm (EN) identifier
      class EuropeanNorm < SingleIdentifier
        TYPED_STAGES = [
          # Published (puben): 60.00-60.60 + publication milestones (65.xx)
          Components::TypedStage.new(
            code: :puben,
            stage_code: :published,
            type_code: :en,
            abbr: ["EN"],
            name: "European Norm",
            harmonized_stages: %w[60.00 60.55 60.60 65.31 65.51 65.62],
          ),
          # Preliminary (pwien): proposal/WI stages
          Components::TypedStage.new(
            code: :pwien,
            stage_code: :preliminary,
            type_code: :en,
            abbr: ["pWI EN"],
            name: "Preliminary Work Item EN",
            harmonized_stages: %w[00.60 10.98 10.99 20.60],
          ),
          # Proposal (pren): working draft stages + split/merge interruption end
          Components::TypedStage.new(
            code: :pren,
            stage_code: :proposal,
            type_code: :en,
            abbr: ["prEN"],
            name: "Proposal European Norm",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.97 30.98 30.99],
          ),
          # Final Proposal (fpren): enquiry stages
          Components::TypedStage.new(
            code: :fpren,
            stage_code: :final_proposal,
            type_code: :en,
            abbr: ["FprEN"],
            name: "Final Proposal European Norm",
            harmonized_stages: %w[40.00 40.20 40.60 40.92 40.97 40.98 40.99],
          ),
          # Formal Vote (fven): COCOR + FV dispatch stages
          Components::TypedStage.new(
            code: :fven,
            stage_code: :formal_vote,
            type_code: :en,
            abbr: ["FV prEN"],
            name: "Formal Vote EN",
            harmonized_stages: %w[43.20 43.60 43.97 43.98 45.97 45.98 45.99],
          ),
          # Vote (ven): enquiry/vote stages
          Components::TypedStage.new(
            code: :ven,
            stage_code: :vote,
            type_code: :en,
            abbr: ["vEN"],
            name: "Vote EN",
            harmonized_stages: %w[50.20 50.60 50.97 50.98],
          ),
          # Review (rven): 2-year review stages
          Components::TypedStage.new(
            code: :rven,
            stage_code: :review,
            type_code: :en,
            abbr: ["rvEN"],
            name: "Review EN",
            harmonized_stages: %w[90.00 90.20 90.60 90.92 90.93 90.98],
          ),
          # Reactivation (racen): re-activation stage
          Components::TypedStage.new(
            code: :racen,
            stage_code: :reactivation,
            type_code: :en,
            abbr: ["racEN"],
            name: "Re-activated EN",
            harmonized_stages: %w[96.60],
          ),
          # Withdrawn (wden): withdrawal stage
          Components::TypedStage.new(
            code: :wden,
            stage_code: :withdrawn,
            type_code: :en,
            abbr: ["wdEN"],
            name: "Withdrawn EN",
            harmonized_stages: %w[99.60],
          ),
        ].freeze

        def self.type
          { key: :en,
            web: :european_norm, title: "European Norm", short: "EN" }
        end
      end
    end
  end
end
