module NistPubid
  module Series
    class FipsPub < NistPubid::Serie
      EDITION_REGEXP = /\d+-\d+(?<prepend>-)(?<year>\d{4})|
                        (?:\d+-)?(?<date_with_month>[A-Za-z]{3}\d{4})|
                        (?:\d+-)?(?<date_with_day>[A-Za-z]{3}\d{2}\/\d{4})/x.freeze
      SERIE_REGEXP = /(NIST FIPS( PUB)?)/.freeze
      REVISION_REGEXP = /(?:[\daA-Z](?:rev|r|Rev\.\s)|, Revision )([\da]+|$|\w+\d{4})/.freeze

      def parse_docnumber(code, code_original)
        super(code.gsub("NIST FIPS 54-Jan15", "NIST FIPS 54"), code_original)
      end
    end
  end
end
