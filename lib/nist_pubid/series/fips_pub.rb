module NistPubid
  module Series
    class FipsPub < NistPubid::Serie
      SERIE_REGEXP = /NIST FIPS( PUB)?/.freeze

      def parse_docnumber(code, code_original)
        super(code.gsub("NIST FIPS 54-Jan15", "NIST FIPS 54"), code_original)
      end

      def self.match?(code)
        SERIE_REGEXP.match?(code)
      end

      def self.parse(code)
        new(serie: "FIPS PUB", parsed: SERIE_REGEXP.match(code).to_s)
      end
    end
  end
end
