# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      autoload :Amendment, "#{__dir__}/identifiers/amendment"
      autoload :Annex, "#{__dir__}/identifiers/annex"
      autoload :BasicPublication, "#{__dir__}/identifiers/basic_publication"
      autoload :Bulletin, "#{__dir__}/identifiers/bulletin"
      autoload :CodeNumber, "#{__dir__}/identifiers/code_number"
      autoload :Document, "#{__dir__}/identifiers/document"
      autoload :Errata, "#{__dir__}/identifiers/errata"
      autoload :ExpertReport, "#{__dir__}/identifiers/expert_report"
      autoload :Guide, "#{__dir__}/identifiers/guide"
      autoload :Recommendation, "#{__dir__}/identifiers/recommendation"
      autoload :SeminarReport, "#{__dir__}/identifiers/seminar_report"
      autoload :Vocabulary, "#{__dir__}/identifiers/vocabulary"
    end
  end
end
