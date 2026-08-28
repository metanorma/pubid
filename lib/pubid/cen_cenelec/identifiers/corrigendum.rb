# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # Corrigendum Identifier
      # Contains a base identifier plus corrigendum parameters
      class Corrigendum < Base
        attribute :base, Pubid::CenCenelec::Identifier, polymorphic: true
        attribute :corrigendum_number, :string
        attribute :corrigendum_year, :integer
        attribute :corrigendum_month, :string

        def publisher
          base&.publisher
        end
      end
    end
  end
end
