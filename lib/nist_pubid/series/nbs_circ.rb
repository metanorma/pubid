module NistPubid
  module Series
    class NbsCirc < NistPubid::Serie
      EDITION_REGEXP = /\d+(?<prepend>[e-])(?<sequence>\d+)/.freeze

      def parse_edition(code)
        return { sequence: 7, parsed: "" } if /^NBS CIRC sup/.match?(code)

        super
      end

      def parse_docnumber(code, code_original)
        return "24" if /^NBS CIRC sup/.match?(code)

        super
      end

      def parse_supplement(code)
        return "2" if /supJun1925-Jun1926$/.match?(code)

        return "3" if /supJun1925-Jun1927$/.match?(code)

        super
      end
    end
  end
end
