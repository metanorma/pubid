module NistPubid
  module Series
    class NbsCirc < NistPubid::Serie
      EDITION_REGEXP = /\d+(?<prepend>e)(?<sequence>\d+)/.freeze
    end
  end
end
