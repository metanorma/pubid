module NistPubid
  module Series
    class NbsHb < NistPubid::Serie
      EDITION_REGEXP = /\d+(?<prepend1>e)(?<sequence>\d+)|(?<prepend2>-)(?<year>\d{4})/.freeze

      # drop last part for document numbers like NBS HB 44e2-1955
      DOCNUMBER_REGEXP = /(\d+)e\d+-\d+/.freeze

      def parse_edition(code)
        edition = EDITION_REGEXP.match(code)

        parsed = edition&.captures&.join&.to_s

        return nil if edition.nil? || edition.captures.compact.empty?

        if edition.named_captures.key?("year") && edition[:year]
          { year: edition[:year].to_i, parsed: parsed }
        else
          { sequence: edition[:sequence], parsed: parsed }
        end
      end
    end
  end
end
