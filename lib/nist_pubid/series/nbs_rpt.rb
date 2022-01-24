module NistPubid
  module Series
    class NbsRpt < NistPubid::Serie
      SERIE_REGEXP = /NBS report ;|NBS RPT/.freeze
      DOCNUMBER_REGEXP = /(\w{3}-\w{3}\d{4}|ADHOC|div9)/.freeze

      def self.match?(code)
        SERIE_REGEXP.match?(code)
      end

      def self.parse(code)
        new(serie: "NBS RPT", parsed: SERIE_REGEXP.match(code).to_s)
      end
    end
  end
end
