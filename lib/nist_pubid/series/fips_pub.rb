module NistPubid
  module Series
    class FipsPub < NistPubid::Serie
      EDITION_REGEXP = /[0-9]+[A-Za-z]*(?<prepend>-)(?<sequence>\d+)/.freeze
    end
  end
end
