module NistPubid
  module Series
    class NbsHb < NistPubid::Serie
      # 67suppFeb1965
      EDITION_REGEXP = /\d+(?<prepend1>e)(?<sequence>\d+)|(?<prepend2>-)
                         (?<year>\d{4})|supp(?<date_with_month>\w{3}\d{4})/x.freeze

      # drop last part for document numbers like NBS HB 44e2-1955
      DOCNUMBER_REGEXP = /(\d+)e\d+-\d+/.freeze

      def parse_edition(code)
        edition = EDITION_REGEXP.match(code)

        parsed = edition&.captures&.join&.to_s

        return nil if edition.nil? || edition.captures.compact.empty?

        if edition.named_captures.key?("year") && edition[:year]
          { year: edition[:year].to_i, parsed: parsed }
        elsif edition.named_captures.key?("date_with_month") && edition[:date_with_month]
          date = Date.parse("01/" + edition[:date_with_month])
          { month: date.month, year: date.year, parsed: parsed }
        else
          { sequence: edition[:sequence], parsed: parsed }
        end
      end
    end
  end
end
