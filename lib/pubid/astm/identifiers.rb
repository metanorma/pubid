# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      autoload :Base, "#{__dir__}/identifiers/base"
      autoload :CodeNumber, "#{__dir__}/identifiers/code_number"
      autoload :Standard, "#{__dir__}/identifiers/standard"
      autoload :IsoDualPublished, "#{__dir__}/identifiers/iso_dual_published"
      autoload :Manual, "#{__dir__}/identifiers/manual"
      autoload :ResearchReport, "#{__dir__}/identifiers/research_report"
      autoload :DataSeries, "#{__dir__}/identifiers/data_series"
      autoload :TechnicalReport, "#{__dir__}/identifiers/technical_report"
      autoload :Monograph, "#{__dir__}/identifiers/monograph"
      autoload :Adjunct, "#{__dir__}/identifiers/adjunct"
      autoload :WorkInProgress, "#{__dir__}/identifiers/work_in_progress"
    end
  end
end
