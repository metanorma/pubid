# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # Standard NESC identifier with C2-YYYY format
        #
        # Represents the standard National Electrical Safety Code publications
        # using the C2 designation followed by publication year.
        #
        # @example
        #   nesc = Pubid::Ieee.parse("C2-1997 National Electric Safety Code")
        #   nesc.to_s  # => "C2-1997 National Electrical Safety Code"
        class Standard < Base
          include Pubid::Ieee::Identifiers::CodeNumber

          # Distinct from Identifiers::Standard, whose derived polymorphic name
          # is also "pubid:ieee:standard".
          def self.polymorphic_name
            "pubid:ieee:nesc-standard"
          end

          # Render standard NESC identifier
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] C2-YYYY format (bare "C2" when the year is absent,
          #   e.g. a partial reference produced by `#exclude(:year)`)
          def to_s(trademark: false)
            code_part = year ? "C2-#{year}" : "C2"
            result = "#{code_part} National Electrical Safety Code"
            result += Pubid::Ieee.trademark_symbol(result) if trademark
            result
          end
        end
      end
    end
  end
end
