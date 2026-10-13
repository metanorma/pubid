# frozen_string_literal: true

module Pubid
  module Evs
    module Identifiers
      # The EVS adoption of an ISO or IEC standard directly (not via CEN).
      # Examples: "EVS-ISO 9001:2015", "EVS-IEC 62368-1:2020"
      class InternationalAdoption < ::Pubid::Evs::Identifier
        attribute :intl_org, :string
        attribute :number, :string
        attribute :part, :string
        attribute :year, :string
      end
    end
  end
end
