# frozen_string_literal: true

module Pubid
  module Evs
    module Identifiers
      # A plain Estonian standard: "EVS 921:2019", optionally carrying the
      # TS/TR type ("EVS-TS 1:2019").
      class EstonianStandard < ::Pubid::Evs::Identifier
        attribute :number, :string
        attribute :year, :string
        attribute :evs_type, :string
      end
    end
  end
end
