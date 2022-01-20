module NistPubid
  module Series
    class NbsCsm < NistPubid::Serie
      DOCNUMBER_REGEXP = /v(\d+)n(\d+)|(\d+)/.freeze

      def parse_docnumber(code, original_code)
        DOCNUMBER_REGEXP.match(original_code)&.captures&.compact&.join("-")
      end
    end
  end
end
