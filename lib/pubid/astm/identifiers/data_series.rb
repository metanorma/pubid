# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class DataSeries < Base
        include CodeNumber

        attribute :hol_suffix, :boolean # HOL suffix
      end
    end
  end
end
