# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # NESC Redline identifier
        #
        # Represents redline versions of NESC which show changes from
        # previous editions with tracked changes highlighted.
        #
        # @example
        #   nesc = Pubid::Ieee.parse("2017 NESC Redline")
        #   nesc.to_s  # => "2017 NESC Redline"
        class Redline < Base
          # Render redline identifier
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] YYYY NESC Redline format
          def to_s(trademark: false)
            result = "#{year.year} NESC Redline"
            result += Pubid::Ieee.trademark_symbol(result) if trademark
            result
          end
        end
      end
    end
  end
end
