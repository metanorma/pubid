# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class ResearchReport < Base
        include CodeNumber

        attribute :committee, :string # A01, C09

        # Research-report numbers restart per committee, so the committee is
        # part of the identity: "ASTM RR:A01-1001" and "ASTM RR:C09-1001" are
        # different documents. The renderer already prints it; the slug has to
        # carry it too or they share a filename.
        def mr_number_with_part
          mr_join(committee&.downcase, super)
        end
      end
    end
  end
end
