module NistPubid
  module Series
    class FipsPub < NistPubid::Serie
      EDITION_REGEXP = /[0-9]+[A-Za-z]*(?<prepend>-)(?<sequence>\d+)/.freeze

      def parse_docnumber(code, code_original)
        super(code.gsub("NIST FIPS PUB 54-Jan15", "NIST FIPS PUB 54"), code_original)
      end
    end
  end
end
