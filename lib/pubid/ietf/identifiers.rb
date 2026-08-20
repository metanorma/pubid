# frozen_string_literal: true

module Pubid
  module Ietf
    module Identifiers
      autoload :Serialization, "#{__dir__}/identifiers/serialization"
      autoload :Rfc, "#{__dir__}/identifiers/rfc"
      autoload :Bcp, "#{__dir__}/identifiers/bcp"
      autoload :Std, "#{__dir__}/identifiers/std"
      autoload :Fyi, "#{__dir__}/identifiers/fyi"
      autoload :InternetDraft, "#{__dir__}/identifiers/internet_draft"
    end
  end
end
