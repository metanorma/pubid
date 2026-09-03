# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class Monograph < Base
        include CodeNumber

        attribute :edition, :string # 2ND, 4TH
      end
    end
  end
end
