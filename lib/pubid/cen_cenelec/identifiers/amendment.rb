# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # Amendment Identifier
      # Contains a base identifier plus amendment parameters
      class Amendment < Base
        attribute :base, Pubid::CenCenelec::Identifier, polymorphic: true
        attribute :amendment_number, :string
        attribute :amendment_year, :integer

        def publisher
          base&.publisher
        end
      end
    end
  end
end
