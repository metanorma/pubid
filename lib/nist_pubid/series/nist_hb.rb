module NistPubid
  module Series
    class NistHb < NistPubid::Serie
      EDITION_REGEXP = /(?:\d+-)?\d+(?<prepend>-)(?<year>\d{4})/.freeze

      def parse_edition(code)
        super(code.sub("NIST HB 105-1-1990", "NIST HB 105-1r1990"))
      end
    end
  end
end
