# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      autoload :AdoptedStandard, "#{__dir__}/identifiers/adopted_standard"
      autoload :Amendment, "#{__dir__}/identifiers/amendment"
      autoload :ConformanceIdentifier,
               "#{__dir__}/identifiers/conformance_identifier"
      autoload :CodeNumber, "#{__dir__}/identifiers/code_number"
      autoload :Corrigendum, "#{__dir__}/identifiers/corrigendum"
      autoload :CsaDualPublished, "#{__dir__}/identifiers/csa_dual_published"
      autoload :DualIdentifier, "#{__dir__}/identifiers/dual_identifier"
      autoload :DualPublished, "#{__dir__}/identifiers/dual_published"
      autoload :IecIeeeCopublished,
               "#{__dir__}/identifiers/iec_ieee_copublished"
      autoload :InterpretationIdentifier,
               "#{__dir__}/identifiers/interpretation_identifier"
      autoload :JointDevelopment, "#{__dir__}/identifiers/joint_development"
      autoload :MultiNumberedIdentifier,
               "#{__dir__}/identifiers/multi_numbered_identifier"
      autoload :Nesc, "#{__dir__}/identifiers/nesc"
      autoload :ParentheticalIdentifier,
               "#{__dir__}/identifiers/parenthetical_identifier"
      autoload :ProjectDraftIdentifier,
               "#{__dir__}/identifiers/project_draft_identifier"
      autoload :RedlinedStandard, "#{__dir__}/identifiers/redlined_standard"
      autoload :SiStandard, "#{__dir__}/identifiers/si_standard"
      autoload :Standard, "#{__dir__}/identifiers/standard"
      autoload :SupplementIdentifier,
               "#{__dir__}/identifiers/supplement_identifier"
    end
  end
end
