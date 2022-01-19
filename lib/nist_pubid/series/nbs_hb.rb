module NistPubid
  module Series
    class NbsHb < NistPubid::Serie
      EDITION_REGEXP = /\d+(?<prepend>e)(?<sequence>\d+)/.freeze
    end
  end
end
