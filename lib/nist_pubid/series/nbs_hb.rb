module NistPubid
  module Series
    class NbsHb < NistPubid::Serie
      EDITION_REGEXP = /\d+(?<prepend>e)(?<sequence>\d+)/.freeze

      # drop last part for document numbers like NBS HB 44e2-1955
      DOCNUMBER_REGEXP = /(\d+)e\d+-\d+/.freeze
    end
  end
end
