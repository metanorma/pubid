module NistPubid
  module Series
    class NistSp < NistPubid::Serie
      EDITION_REGEXP = /NIST SP \d+[a-zA-Z]?(?<prepend>-)(?<year>\d{4})/.freeze

      # drop last part and edition for NIST SP 782-1995-96
      DOCNUMBER_REGEXP = /(\d+)-\d{4}-\d+/.freeze

      def parse_edition(code)
        return nil if code.include? "NIST SP 250"

        super
      end
    end
  end
end
