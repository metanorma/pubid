# frozen_string_literal: true

module Pubid
  module Evs
    module Identifiers
      autoload :NationalAdoption, "#{__dir__}/identifiers/national_adoption"
      autoload :InternationalAdoption, "#{__dir__}/identifiers/international_adoption"
      autoload :EstonianStandard, "#{__dir__}/identifiers/estonian_standard"
    end
  end
end
