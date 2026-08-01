# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # NESC Handbook identifier
        #
        # Represents NESC Handbook publications which provide comprehensive
        # guidance and interpretation of the National Electrical Safety Code.
        #
        # @example Basic handbook
        #   nesc = Pubid::Ieee.parse("2012 NESC Handbook")
        #   nesc.to_s  # => "IEEE Std 2012 NESC Handbook"
        #
        # @example With edition
        #   nesc = Pubid::Ieee.parse("2017 NESC Handbook, Premier Edition")
        #   nesc.to_s  # => "IEEE Std 2017 NESC Handbook, Premier Edition"
        class Handbook < Base
          # Render handbook identifier
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] YYYY NESC Handbook format with optional edition
          def to_s(trademark: false)
            abbr = "NESC"
            abbr += "(R)" if registered
            parts = ["IEEE Std #{year.year} #{abbr} Handbook"]
            parts << ", #{edition}" if edition
            result = parts.join
            result += Pubid::Ieee.trademark_symbol(result) if trademark
            result
          end
        end
      end
    end
  end
end
