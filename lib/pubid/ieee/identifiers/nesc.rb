# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        autoload :Base, "#{__dir__}/nesc/base"
        autoload :Draft, "#{__dir__}/nesc/draft"
        autoload :Edition, "#{__dir__}/nesc/edition"
        autoload :Handbook, "#{__dir__}/nesc/handbook"
        autoload :Redline, "#{__dir__}/nesc/redline"
        autoload :Standard, "#{__dir__}/nesc/standard"
      end
    end
  end
end
